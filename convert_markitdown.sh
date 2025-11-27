#!/bin/bash
set -e

usage() {
    echo "Usage: $0 --in <input_dir> --out <output_file>"
    echo "Example: $0 --in ./gits/IsaacSim --out ./refs/isaacsim-code.md"
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --in)
            INPUT_DIR="$2"
            shift 2
            ;;
        --out)
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

# Create temp file name (remove empty file so zip can create fresh)
TMP_ZIP=$(mktemp --suffix=.zip)
rm "$TMP_ZIP"

# Activate venv and run
source .venv/bin/activate

zip -r "$TMP_ZIP" "$INPUT_DIR"
markitdown "$TMP_ZIP" -o "$OUTPUT_FILE"
rm "$TMP_ZIP"

echo "Done: $OUTPUT_FILE"
