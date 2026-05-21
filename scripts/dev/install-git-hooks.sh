#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)

cd "$ROOT"
git config --local core.hooksPath .githooks
echo "Configured git hooks: core.hooksPath=.githooks"
