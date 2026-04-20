#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "usage: publish-r2-dict.sh <dict-key> <dict-file> <date> [line-count] [triggered-by]" >&2
  exit 1
fi

DICT_KEY="$1"
DICT_FILE="$2"
DICT_DATE="$3"
LINE_COUNT="${4:-}"
TRIGGERED_BY="${5:-manual-release}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKER_DIR="$ROOT_DIR/workers/gins-rime"
TMP_DIR="${TMPDIR:-/tmp}/gins-rime-dict-release"
LATEST_JSON="$TMP_DIR/latest.json"
LATEST_JSON_REMOTE="$TMP_DIR/latest-remote.json"

mkdir -p "$TMP_DIR"

if [[ -z "${CLOUDFLARE_API_TOKEN:-${CF_API_TOKEN:-}}" ]]; then
  echo "CF_API_TOKEN/CLOUDFLARE_API_TOKEN is not set" >&2
  exit 1
fi

export CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-${CF_API_TOKEN:-}}"

if [[ ! -f "$DICT_FILE" ]]; then
  echo "dict file not found: $DICT_FILE" >&2
  exit 1
fi

cd "$WORKER_DIR"
npx wrangler r2 object get gins-rime/releases/latest.json --remote --file "$LATEST_JSON_REMOTE" >/dev/null 2>&1 || true

python3 - "$LATEST_JSON" "$LATEST_JSON_REMOTE" "$DICT_KEY" "$DICT_DATE" "$LINE_COUNT" "$TRIGGERED_BY" <<'PY'
import json
import sys
from pathlib import Path

out, existing_path, dict_key, dict_date, line_count, triggered_by = sys.argv[1:]
data = {}
path = Path(existing_path)
if path.exists():
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        data = {}

payload = {
    "date": dict_date,
    "url": f"/dicts/{dict_key}.dict.yaml",
    "triggeredBy": triggered_by,
}
if line_count:
    payload["lines"] = int(line_count)

data[dict_key] = payload

with open(out, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY

echo "Uploading dict: $DICT_KEY"
npx wrangler r2 object put "gins-rime/dicts/${DICT_KEY}.dict.yaml" --remote --file "$DICT_FILE" --content-type text/yaml --cache-control "public, max-age=3600"

echo "Updating releases/latest.json"
npx wrangler r2 object put gins-rime/releases/latest.json --remote --file "$LATEST_JSON" --content-type application/json --cache-control "public, max-age=300"

echo "Dictionary publish complete."
