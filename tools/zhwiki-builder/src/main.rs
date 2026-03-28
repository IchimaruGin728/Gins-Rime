use anyhow::{Context, Result};
use bzip2::read::BzDecoder;
use clap::Parser;
use indicatif::{ProgressBar, ProgressStyle};
use pinyin::ToPinyin;
use quick_xml::events::Event;
use quick_xml::reader::Reader;
use regex::Regex;
use std::collections::HashSet;
use std::fs::File;
use std::io::{BufReader, BufWriter, Write};
use std::path::PathBuf;
use tracing::{debug, info, warn};

#[derive(Parser)]
#[command(name = "zhwiki-builder")]
#[command(about = "Build zhwiki pinyin dictionary for RIME from Wikipedia dump")]
struct Cli {
    /// Path to zhwiki-latest-pages-articles.xml.bz2
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

    info!("Reading dump: {}", cli.input.display());

    let file = File::open(&cli.input).context("Failed to open input file")?;
    let decompressor = BzDecoder::new(file);
    let buf_reader = BufReader::with_capacity(8 * 1024 * 1024, decompressor);
    let mut reader = Reader::from_reader(buf_reader);
    reader.config_mut().trim_text(true);

    let mut titles: Vec<String> = Vec::new();
    let mut buf = Vec::new();
    let mut in_title = false;
    let mut current_ns: Option<String> = None;
    let mut in_ns = false;

    // Regex to filter out non-article titles
    let skip_re = Regex::new(r"^(Wikipedia|Template|Category|File|Help|Portal|Draft|Module|MediaWiki|User|Talk|Special):").unwrap();
    let cjk_re = Regex::new(r"[\u4e00-\u9fff]").unwrap();

    let pb = ProgressBar::new_spinner();
    pb.set_style(
        ProgressStyle::default_spinner()
            .template("{spinner:.green} [{elapsed_precise}] {msg}")
            .unwrap(),
    );

    info!("Parsing XML dump...");

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) => match e.name().as_ref() {
                b"title" => in_title = true,
                b"ns" => in_ns = true,
                _ => {}
            },
            Ok(Event::Text(e)) => {
                if in_title {
                    let title = e.unescape().unwrap_or_default().to_string();
                    // Only process article namespace (ns=0) titles
                    if !skip_re.is_match(&title)
                        && cjk_re.is_match(&title)
                        && title.chars().count() >= cli.min_len
                        && title.chars().count() <= cli.max_len
                        && !title.contains('/')
                        && !title.contains('(')
                    {
                        titles.push(title);
                    }
                    in_title = false;
                } else if in_ns {
                    current_ns = Some(e.unescape().unwrap_or_default().to_string());
                    in_ns = false;
                }
            }
            Ok(Event::End(e)) => match e.name().as_ref() {
                b"title" => in_title = false,
                b"ns" => in_ns = false,
                _ => {}
            },
            Ok(Event::Eof) => break,
            Err(e) => {
                warn!("XML parse error: {e}, skipping");
            }
            _ => {}
        }
        buf.clear();

        if titles.len() % 10000 == 0 && titles.len() > 0 {
            pb.set_message(format!("Extracted {} titles", titles.len()));
        }
    }

    pb.finish_with_message(format!("Total titles extracted: {}", titles.len()));

    // Deduplicate
    let mut seen = HashSet::new();
    titles.retain(|t| seen.insert(t.clone()));
    info!("Unique titles after dedup: {}", titles.len());

    // Generate pinyin and write dict.yaml
    info!("Generating pinyin and writing to {}", cli.output.display());

    let out_file = File::create(&cli.output).context("Failed to create output file")?;
    let mut writer = BufWriter::new(out_file);

    // Write RIME dict header
    writeln!(writer, "# Gins-Rime zhwiki dictionary")?;
    writeln!(writer, "# Auto-generated from Chinese Wikipedia dump")?;
    writeln!(writer, "# Source: zhwiki-latest-pages-articles.xml.bz2")?;
    writeln!(writer, "---")?;
    writeln!(writer, "name: zhwiki")?;
    writeln!(writer, "version: \"0.1\"")?;
    writeln!(writer, "sort: by_weight")?;
    writeln!(writer, "...")?;
    writeln!(writer)?;

    let mut count = 0u64;
    for title in &titles {
        if let Some(pinyin_str) = to_pinyin_with_tone(title) {
            writeln!(writer, "{}\t{}", title, pinyin_str)?;
            count += 1;
        }
    }

    info!("Written {} entries to dict", count);
    Ok(())
}

/// Convert a Chinese string to pinyin with tone marks (万象 format).
/// Returns None if the string contains characters that can't be converted.
fn to_pinyin_with_tone(s: &str) -> Option<String> {
    let mut parts = Vec::new();
    for ch in s.chars() {
        if let Some(pinyin) = ch.to_pinyin() {
            parts.push(pinyin.with_tone().to_string());
        } else if ch.is_ascii_alphanumeric() || ch == '·' || ch == '-' {
            // Keep ASCII chars and interpuncts as-is
            parts.push(ch.to_string());
        } else if ch.is_ascii_whitespace() {
            // Skip whitespace in encoding
            continue;
        } else {
            // Non-CJK, non-ASCII char — skip this title
            debug!("Skipping title with unmappable char '{}': {}", ch, s);
            return None;
        }
    }

    if parts.is_empty() {
        return None;
    }

    Some(parts.join(" "))
}
