#!/usr/bin/env bash
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$ROOT" ]; then
    echo "pre-commit: must run inside a git worktree" >&2
    exit 1
fi

cd "$ROOT"

if ! command -v bun >/dev/null 2>&1; then
    echo "pre-commit: bun is required to check generated skill drift" >&2
    exit 1
fi

echo "pre-commit: checking generated intuitive skills"
bun run build:skills:check
