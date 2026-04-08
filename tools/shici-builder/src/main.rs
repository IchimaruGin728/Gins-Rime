use anyhow::{Context, Result};
use clap::Parser;
use indicatif::{ProgressBar, ProgressStyle};
use opencc_rust::{DefaultConfig, OpenCC};
use pinyin::ToPinyin;
use rayon::prelude::*;
use regex::Regex;
use serde::Deserialize;
use std::collections::HashSet;
use std::fs::{self, File};
use std::io::{BufRead, BufReader, BufWriter, Write};
use std::path::PathBuf;
use tracing::{info, warn};

#[derive(Parser)]
#[command(name = "shici-builder")]
#[command(about = "Build classical poetry dictionary for RIME, deduped against 万象 shici")]
struct Cli {
    #[arg(short, long)]
    poetry_dir: PathBuf,

    #[arg(short, long)]
    core_shici: PathBuf,

    #[arg(short, long, default_value = "gins-shici.dict.yaml")]
    output: PathBuf,

    #[arg(long, default_value_t = 3)]
    min_len: usize,

    #[arg(long, default_value_t = 20)]
    max_len: usize,
}

#[derive(Deserialize)]
struct Poem {
    title: Option<String>,
    #[serde(default)]
    paragraphs: Vec<String>,
    rhythmic: Option<String>,
}

fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env().add_directive("shici_builder=info".parse().unwrap()))
        .init();

    let cli = Cli::parse();
    let t2s = OpenCC::new(DefaultConfig::T2S).map_err(|e| anyhow::anyhow!("OpenCC init failed: {}", e))?;

    info!("Loading core shici for dedup...");
    let core_set = load_core_shici(&cli.core_shici)?;
    
    let punct_re = Regex::new(r#"[，。？！、；：「」『』【】《》〈〉""''…—～\s]"#).unwrap();
    let cjk_re = Regex::new(r"[\u4e00-\u9fff\u3400-\u4dbf]").unwrap();

    let pb = ProgressBar::new_spinner();
    pb.set_style(ProgressStyle::default_spinner().template("{spinner:.green} [{elapsed_precise}] {msg}").unwrap());

    let json_files = collect_json_files(&cli.poetry_dir);
    info!("Found {} JSON files", json_files.len());

    let mut texts: Vec<String> = Vec::with_capacity(200_000);

    for path in &json_files {
        pb.set_message(format!("Processing {}", path.file_name().unwrap_or_default().to_string_lossy()));

        let file = File::open(path)?;
        let reader = BufReader::new(file);
        let poems: Vec<Poem> = match serde_json::from_reader(reader) {
            Ok(p) => p,
            Err(e) => {
                warn!("Skip malformed JSON {}: {}", path.display(), e);
                continue;
            }
        };

        for poem in &poems {
            let title = poem.title.as_deref().or(poem.rhythmic.as_deref()).unwrap_or("");
            let mut candidates: Vec<&str> = vec![title];
            for line in &poem.paragraphs {
                candidates.push(line.as_str());
            }

            for raw in candidates {
                let cleaned = punct_re.replace_all(raw, "").to_string();
                if cleaned.is_empty() || !cjk_re.is_match(&cleaned) {
                    continue;
                }

                let normalized = t2s.convert(&cleaned);
                let char_count = normalized.chars().count();

                if char_count >= cli.min_len && char_count <= cli.max_len && !core_set.contains(&normalized) {
                    texts.push(normalized);
                }
            }
        }
    }

    pb.finish_with_message(format!("Collected {} texts", texts.len()));

    texts.sort_unstable();
    texts.dedup();

    info!("Generating pinyin...");
    let mut entries: Vec<(String, String)> = texts
        .par_iter()
        .filter_map(|t| to_pinyin_toned(t).map(|py| (t.clone(), py)))
        .collect();

    entries.sort_unstable_by(|a, b| a.0.cmp(&b.0));

    info!("Writing to {}", cli.output.display());
    let out = File::create(&cli.output).context("Output creation failed")?;
    let mut writer = BufWriter::with_capacity(1024 * 1024, out);

    writeln!(writer, "# Gins-Rime classical poetry dictionary\n---\nname: gins-shici\nversion: \"0.1\"\nsort: by_weight\n...\n")?;
    for (text, py) in &entries {
        writeln!(writer, "{}\t{}", text, py)?;
    }

    info!("Done: {} entries", entries.len());
    Ok(())
}

fn load_core_shici(path: &PathBuf) -> Result<HashSet<String>> {
    let file = File::open(path)?;
    let reader = BufReader::new(file);
    let mut set = HashSet::with_capacity(330_000);
    let mut in_body = false;

    for line in reader.lines() {
        let line = line?;
        if line.starts_with("...") { in_body = true; continue; }
        if !in_body || line.starts_with('#') || line.is_empty() { continue; }
        if let Some(text) = line.split('\t').next() {
            set.insert(text.to_string());
        }
    }
    Ok(set)
}

fn collect_json_files(dir: &PathBuf) -> Vec<PathBuf> {
    let mut result = Vec::new();
    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                result.extend(collect_json_files(&path));
            } else if path.extension().and_then(|e| e.to_str()) == Some("json") {
                result.push(path);
            }
        }
    }
    result
}

fn to_pinyin_toned(s: &str) -> Option<String> {
    let mut parts = Vec::with_capacity(s.len());
    for ch in s.chars() {
        if let Some(py) = ch.to_pinyin() {
            parts.push(py.with_tone().to_string());
        } else if ch.is_ascii_alphanumeric() || ch == '·' || ch == '-' {
            parts.push(ch.to_string());
        } else if ch.is_ascii_whitespace() {
            continue;
        } else {
            return None;
        }
    }
    if parts.is_empty() { None } else { Some(parts.join(" ")) }
}
