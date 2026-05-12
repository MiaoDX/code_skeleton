#!/bin/bash
# Dirty patches for in-flux upstream versions (gsd, codex, ...).
# Each fix is idempotent and self-detects; runs are safe to repeat.
# When upstream catches up, drop the matching function — leave the
# scaffolding so the script keeps working as a no-op.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

section() { echo ""; echo "── $1 ──"; }
note()    { echo "  · $1"; }
ok()      { echo "  ✓ $1"; }
skip()    { echo "  - $1"; }

# ─────────────────────────────────────────────────────────────────
# Add new fixes above this line. Keep each one self-contained,
# idempotent, and clearly marked with the upstream version it
# patches around.
# ─────────────────────────────────────────────────────────────────

main() {
    echo "tmp-fix: no active fixes."
}

main "$@"
