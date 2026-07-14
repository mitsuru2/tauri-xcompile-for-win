#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../src"
OUTPUT_PATH="$OUTPUT_DIR/_license.ts"
TMP_PATH="$OUTPUT_PATH.tmp"

# PRIMENG_LICENSE_KEY は環境変数として供給される。
LICENSE_KEY="${PRIMENG_LICENSE_KEY:-}"
if [ -z "$LICENSE_KEY" ]; then
  echo "[generate-license] PRIMENG_LICENSE_KEY が未設定です。.devcontainer/secrets.env を確認してください。" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# アトミック書き込み
echo "export const primeNgLicense = '$LICENSE_KEY';" > "$TMP_PATH"
mv "$TMP_PATH" "$OUTPUT_PATH"

echo "PrimeNG license saved to $OUTPUT_PATH"