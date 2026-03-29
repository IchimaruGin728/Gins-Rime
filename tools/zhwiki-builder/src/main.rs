use anyhow::{Context, Result};
use clap::Parser;
use flate2::read::GzDecoder;
use indicatif::{ProgressBar, ProgressStyle};
use opencc_rust::{DefaultConfig, OpenCC};
use pinyin::ToPinyin;
use rayon::prelude::*;
use regex::Regex;
use std::fs::File;
use std::io::{BufRead, BufReader, BufWriter, Write};
use std::path::PathBuf;
use tracing::info;

#[derive(Parser)]
#[command(name = "zhwiki-builder")]
#[command(about = "Build zhwiki pinyin dictionary for RIME from Wikipedia titles file")]
struct Cli {
    /// Path to zhwiki-latest-all-titles-in-ns0.gz
    #[arg(short, long)]
    input: PathBuf,

    /// Output dict.yaml path
    #[arg(short, long, default_value = "zhwiki.dict.yaml")]
    output: PathBuf,

    /// Minimum title length (characters)
    #[arg(long, default_value_t = 2)]
    min_len: usize,

    /// Maximum title length (characters)
    #[arg(long, default_value_t = 20)]
    max_len: usize,
}

fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::from_default_env()
                .add_directive("zhwiki_builder=info".parse().unwrap()),
        )
        .init();

    let cli = Cli::parse();

    let t2s = OpenCC::new(DefaultConfig::T2S)
        .map_err(|e| anyhow::anyhow!("Failed to init OpenCC T2S: {}", e))?;

    info!("Reading titles: {}", cli.input.display());

    let file = File::open(&cli.input).context("Failed to open input file")?;
    let reader = BufReader::with_capacity(4 * 1024 * 1024, GzDecoder::new(file));

    // Skip known non-article prefixes
    let skip_re = Regex::new(
        r"^(Wikipedia|Template|Category|File|Help|Portal|Draft|Module|MediaWiki|User|Talk|Special)[\s:]"
    ).unwrap();
    let cjk_re = Regex::new(r"[\u4e00-\u9fff\u3400-\u4dbf]").unwrap();

    let pb = ProgressBar::new_spinner();
    pb.set_style(
        ProgressStyle::default_spinner()
            .template("{spinner:.green} [{elapsed_precise}] {msg}")
            .unwrap(),
    );

    // Phase 1: Read lines, filter, convert
    let mut titles: Vec<String> = Vec::with_capacity(200_000);

    for line in reader.lines() {
        let line = line.context("Failed to read line")?;
        let text = line.trim();

        if text.is_empty()
            || skip_re.is_match(text)
            || !cjk_re.is_match(text)
            || text.contains('/')
            || text.contains('(')
        {
            continue;
        }

        let normalized = t2s.convert(text);
        let char_count = normalized.chars().count();

        if char_count >= cli.min_len
            && char_count <= cli.max_len
            && cjk_re.is_match(&normalized)
        {
            titles.push(normalized);
        }

        if titles.len() % 50_000 == 0 && !titles.is_empty() {
            pb.set_message(format!("Processed {} titles", titles.len()));
        }
    }

    pb.finish_with_message(format!("Total titles: {}", titles.len()));

    // Phase 2: Sort + dedup
    titles.sort_unstable();
    titles.dedup();
    info!("Unique: {}", titles.len());

    // Phase 3: Parallel pinyin generation
    info!("Generating pinyin...");
    let mut entries: Vec<(String, String)> = titles
        .par_iter()
        .filter_map(|t| to_pinyin_toned(t).map(|py| (t.clone(), py)))
        .collect();

    entries.sort_unstable_by(|a, b| a.0.cmp(&b.0));
    info!("Entries with pinyin: {}", entries.len());

    // Phase 4: Write dict.yaml
    info!("Writing to {}", cli.output.display());
    let out = File::create(&cli.output).context("Failed to create output")?;
    let mut writer = BufWriter::with_capacity(1024 * 1024, out);

    writeln!(writer, "# Gins-Rime zhwiki dictionary")?;
    writeln!(writer, "# Simplified Chinese — OpenCC T2S")?;
    writeln!(writer, "---")?;
    writeln!(writer, "name: zhwiki")?;
    writeln!(writer, "version: \"0.1\"")?;
    writeln!(writer, "sort: by_weight")?;
    writeln!(writer, "...")?;
    writeln!(writer)?;

    for (title, py) in &entries {
        writeln!(writer, "{}\t{}", title, py)?;
    }

    info!("Done: {} entries", entries.len());
    Ok(())
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
