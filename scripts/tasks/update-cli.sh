#!/bin/bash

run_global_cli_tools() {
    # Keep all global npm installs in one command so they do not race on the same prefix.
    # Suppress npm output; errors still go to stderr.
    npm install -g --silent \
        @anthropic-ai/claude-code \
        claude-fetch-setup \
        @google/gemini-cli \
        @openai/codex \
        happy-coder \
        opencode-ai@latest \
        2>&1 | grep -E '^npm (error|warn)' || true

    echo "  ✓ claude $(claude --version 2>/dev/null)"
    echo "  ✓ codex $(codex --version 2>/dev/null)"
    echo "  ✓ gemini-cli"
    echo "  ✓ happy-coder"
    echo "  ✓ opencode-ai"
}

run_gsd_workflow() {
    # Suppress verbose GSD output; only show warnings/errors
    npx -y get-shit-done-cc --claude --global 2>&1 | grep -E '^  [⚠✗!]' || true
    npx -y get-shit-done-cc --codex --global 2>&1 | grep -E '^  [⚠✗!]' || true

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
    fi

    local gsd_version
    gsd_version=$(cat ~/.claude/get-shit-done/VERSION 2>/dev/null || echo "?")
    echo "  ✓ gsd v$gsd_version (claude + codex)"
}

run_mcp_fetch() {
    # Suppress verbose output; only show errors
    claude-fetch-setup >/dev/null 2>&1 || {
        echo "  ! claude-fetch-setup failed"
        return 1
    }
    echo "  ✓ mcp-fetch"
}

run_codex_statusline() {
    local config_file="$HOME/.codex/config.toml"
    node "$SCRIPT_DIR/lib/ensure-codex-config.js" "$config_file"

    echo "  ✓ codex status line includes current-dir, context-used, fast-mode, and thread-title"
}
