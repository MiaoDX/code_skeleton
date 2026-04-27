#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
MARKITDOWN_BIN="$REPO_DIR/.venv/bin/markitdown"

INPUT_DIR=""
OUTPUT_FILE=""

usage() {
    echo "Usage: $0 --in <input_dir> --out <output_file>"
    echo "Example: $0 --in ./vendor/repo --out ./context/repo.md"
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --in)
            [[ $# -ge 2 ]] || usage
            INPUT_DIR="$2"
            shift 2
            ;;
        --out)
            [[ $# -ge 2 ]] || usage
            OUTPUT_FILE="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

# Validate arguments
if [[ -z "$INPUT_DIR" || -z "$OUTPUT_FILE" ]]; then
    usage
fi

if [[ ! -d "$INPUT_DIR" ]]; then
    echo "Error: Input directory '$INPUT_DIR' does not exist"
    exit 1
fi

if [[ ! -x "$MARKITDOWN_BIN" ]]; then
    echo "Error: markitdown not found at '$MARKITDOWN_BIN'"
    exit 1
fi

# Create temp file name (remove empty file so zip can create fresh)
TMP_BASE=$(mktemp /tmp/convert-docs-XXXXXX)
TMP_ZIP="${TMP_BASE}.zip"
cleanup() {
    rm -f "$TMP_BASE" "$TMP_ZIP"
}
trap cleanup EXIT
rm -f "$TMP_BASE"

mkdir -p "$(dirname "$OUTPUT_FILE")"

zip -r "$TMP_ZIP" "$INPUT_DIR"
"$MARKITDOWN_BIN" "$TMP_ZIP" -o "$OUTPUT_FILE"

echo "Done: $OUTPUT_FILE"
