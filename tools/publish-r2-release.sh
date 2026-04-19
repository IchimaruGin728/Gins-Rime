#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKER_DIR="$ROOT_DIR/workers/gins-rime"
TMP_DIR="${TMPDIR:-/tmp}/gins-rime-release"
SCHEME_DIR="${SCHEME_DIR:-$ROOT_DIR/dist/test_scheme}"
MODEL_FILE="${MODEL_FILE:-$ROOT_DIR/wanxiang-lts-zh-hans.gram}"
CLI_FILE="${CLI_FILE:-$ROOT_DIR/tools/gins-rime-cli/.build/x86_64-apple-macosx/release/GinsRime}"
CLI_VERSION="${CLI_VERSION:-1.0.0}"
CLI_DATE="${CLI_DATE:-$(date -u +%Y-%m-%d)}"
CLI_SHA="${CLI_SHA:-$(git -C "$ROOT_DIR" rev-parse --short HEAD)}"
SCHEME_VERSION="${SCHEME_VERSION:-$(date -u +%Y%m%d%H%M)}"
MODEL_DATE="${MODEL_DATE:-$(date -u +%Y%m%d)}"

mkdir -p "$TMP_DIR"
SCHEME_TAR="$TMP_DIR/scheme.tar.gz"
LATEST_JSON="$TMP_DIR/latest.json"
LATEST_JSON_REMOTE="$TMP_DIR/latest-remote.json"
CLI_META_JSON="$TMP_DIR/cli-meta.json"

if [[ ! -d "$SCHEME_DIR" ]]; then
  echo "scheme dir not found: $SCHEME_DIR" >&2
  exit 1
fi

if [[ ! -f "$MODEL_FILE" ]]; then
  echo "model file not found: $MODEL_FILE" >&2
  exit 1
fi

if [[ ! -f "$CLI_FILE" ]]; then
  echo "cli file not found: $CLI_FILE" >&2
  exit 1
fi

echo "Packaging scheme from $SCHEME_DIR"
tar -czf "$SCHEME_TAR" -C "$SCHEME_DIR" .

cd "$WORKER_DIR"

npx wrangler r2 object get gins-rime/releases/latest.json --remote --file "$LATEST_JSON_REMOTE" >/dev/null 2>&1 || true

python3 - "$LATEST_JSON" "$LATEST_JSON_REMOTE" "$SCHEME_VERSION" "$MODEL_DATE" "$CLI_VERSION" "$CLI_DATE" "$CLI_SHA" <<'PY'
import json
import sys
from pathlib import Path

out, existing_path, scheme_version, model_date, cli_version, cli_date, cli_sha = sys.argv[1:]
data = {}
path = Path(existing_path)
if path.exists():
    data = json.loads(path.read_text(encoding="utf-8"))

data["scheme"] = {
    "version": scheme_version,
    "url": "/releases/scheme.tar.gz",
    "triggeredBy": "manual-release",
}
data["model"] = {
    "date": model_date,
    "url": "/models/wanxiang-lts-zh-hans.gram",
}
data["cli"] = {
    "version": cli_version,
    "date": cli_date,
    "sha": cli_sha,
    "url": "/releases/latest/gins-rime",
}
with open(out, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

python3 - "$CLI_META_JSON" "$CLI_VERSION" "$CLI_DATE" "$CLI_SHA" <<'PY'
import json
import sys

out, cli_version, cli_date, cli_sha = sys.argv[1:]
data = {
    "version": cli_version,
    "date": cli_date,
    "sha": cli_sha,
}
with open(out, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

echo "Uploading scheme.tar.gz"
npx wrangler r2 object put gins-rime/releases/scheme.tar.gz --remote --file "$SCHEME_TAR" --content-type application/gzip --cache-control "public, max-age=3600"

echo "Uploading model"
npx wrangler r2 object put gins-rime/models/wanxiang-lts-zh-hans.gram --remote --file "$MODEL_FILE" --content-type application/octet-stream --cache-control "public, max-age=3600"

echo "Uploading CLI binary"
npx wrangler r2 object put gins-rime/releases/latest/gins-rime --remote --file "$CLI_FILE" --content-type application/octet-stream --content-disposition 'attachment; filename="gins-rime"' --cache-control "public, max-age=3600"

echo "Uploading cli/meta.json"
npx wrangler r2 object put gins-rime/cli/meta.json --remote --file "$CLI_META_JSON" --content-type application/json --cache-control "public, max-age=300"

echo "Uploading releases/latest.json"
npx wrangler r2 object put gins-rime/releases/latest.json --remote --file "$LATEST_JSON" --content-type application/json --cache-control "public, max-age=300"

echo "Release publish complete."
