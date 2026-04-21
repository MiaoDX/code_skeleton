#!/bin/bash

run_global_cli_tools() {
    # Keep all global npm installs in one command so they do not race on the same prefix.
    npm install -g --loglevel=error \
        @anthropic-ai/claude-code \
        claude-fetch-setup \
        @google/gemini-cli \
        @openai/codex \
        happy-coder \
        opencode-ai@latest

    echo "  ✓ claude $(claude --version 2>/dev/null)"
    echo "  ✓ codex $(codex --version 2>/dev/null)"
    echo "  ✓ gemini-cli"
    echo "  ✓ happy-coder"
    echo "  ✓ opencode-ai"
}

run_gsd_workflow() {
    npx -y get-shit-done-cc --claude --global
    npx -y get-shit-done-cc --codex --global

    # Remove context-monitor PostToolUse hook — we rely on auto-compact instead (GSD #976).
    # GSD's config-set only writes per-project .planning/config.json, so we strip the
    # hook entry from the global settings.json directly.
    local settings="$HOME/.claude/settings.json"
    if [ -f "$settings" ] && command -v jq >/dev/null 2>&1; then
        local tmp
        tmp=$(jq '
          if .hooks.PostToolUse then
            .hooks.PostToolUse |= map(
              select(.hooks | any(.command | test("gsd-context-monitor")) | not)
            )
          else . end
        ' "$settings") && printf '%s\n' "$tmp" > "$settings"
        echo "  ✓ removed gsd-context-monitor hook from settings.json"
    fi

    echo "  ✓ gsd (claude + codex)"
}

run_mcp_fetch() {
    claude-fetch-setup
    echo "  ✓ claude-fetch-setup"
}

run_codex_statusline() {
    local config_file="$HOME/.codex/config.toml"
    node "$SCRIPT_DIR/lib/ensure-codex-config.js" "$config_file"

    echo "  ✓ codex status line includes current-dir, context-used, fast-mode, and thread-title"
}
