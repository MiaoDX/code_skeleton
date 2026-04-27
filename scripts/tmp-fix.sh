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
# Fix: codex 0.125.0 changed ~/.codex/config.toml schema.
#   [[agents]]   →  [agents.<name>]      (struct of structs)
#   [[hooks]]    →  [[hooks.<Event>]]    (struct of arrays)
# gstack/get-shit-done installer still emits the old form.
# Remove this fix once the installer is updated upstream.
# ─────────────────────────────────────────────────────────────────
fix_codex_config_schema() {
    local cfg="$HOME/.codex/config.toml"
    if [ ! -f "$cfg" ]; then
        skip "$cfg not found"
        return 0
    fi

    if ! grep -qE '^\[\[agents\]\]|^\[\[hooks\]\]' "$cfg"; then
        skip "config.toml already in struct form"
        return 0
    fi

    local backup="$cfg.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$cfg" "$backup"
    note "backup: $backup"

    python3 - "$cfg" <<'PY'
import sys, re, pathlib

path = pathlib.Path(sys.argv[1])
lines = path.read_text().splitlines()
out = []
i, n = 0, len(lines)

def consume_block(start_i):
    j = start_i
    body = []
    while j < n:
        s = lines[j].lstrip()
        if s.startswith('[') and not s.startswith('#'):
            break
        body.append(lines[j])
        j += 1
    return body, j

def extract(body, key):
    kept, value = [], None
    pat = re.compile(rf'\s*{re.escape(key)}\s*=\s*"([^"]+)"\s*$')
    for ln in body:
        m = pat.match(ln)
        if m and value is None:
            value = m.group(1)
        else:
            kept.append(ln)
    return value, kept

while i < n:
    line = lines[i]
    stripped = line.strip()
    if stripped == '[[agents]]':
        body, i = consume_block(i + 1)
        name, kept = extract(body, 'name')
        if not name:
            sys.exit('[[agents]] block missing name=')
        out.append(f'[agents.{name}]')
        out.extend(kept)
        continue
    if stripped == '[[hooks]]':
        body, i = consume_block(i + 1)
        event, kept = extract(body, 'event')
        if not event:
            sys.exit('[[hooks]] block missing event=')
        out.append(f'[[hooks.{event}]]')
        out.extend(kept)
        continue
    out.append(line)
    i += 1

path.write_text('\n'.join(out) + '\n')
PY

    ok "rewrote [[agents]] → [agents.<name>] and [[hooks]] → [[hooks.<Event>]]"
}

# ─────────────────────────────────────────────────────────────────
# Add new fixes above this line. Keep each one self-contained,
# idempotent, and clearly marked with the upstream version it
# patches around.
# ─────────────────────────────────────────────────────────────────

main() {
    section "codex config schema"
    fix_codex_config_schema

    echo
    echo "tmp-fix: done."
}

main "$@"
