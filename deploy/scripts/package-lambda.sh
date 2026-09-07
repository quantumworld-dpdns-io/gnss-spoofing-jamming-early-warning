#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${1:-$ROOT/deploy/terraform/.build/alert-ingest.zip}"
mkdir -p "$(dirname "$OUT")"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp "$ROOT/src/alert-ingest/handler.py" "$TMP/"
cp "$ROOT/src/alert-ingest/requirements.txt" "$TMP/"
(cd "$TMP" && zip -qr "$OUT" .)
echo "wrote $OUT"
