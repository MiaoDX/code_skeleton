#!/bin/bash

run_global_cli_tools() {
    # Keep all global npm installs in one command so they do not race on the same prefix.
    npm install -g --loglevel=error \
        @anthropic-ai/claude-code \
        claude-fetch-setup \
        @openai/codex \
        happy-coder \
        opencode-ai@latest \
        pyright

    echo "  ✓ claude $(claude --version 2>/dev/null)"
    echo "  ✓ codex $(codex --version 2>/dev/null)"
    echo "  ✓ happy-coder"
    echo "  ✓ opencode-ai"
    echo "  ✓ pyright $(pyright --version 2>/dev/null)"
}

run_claude_plugins() {
    local out

    out=$(claude plugin marketplace add anthropics/claude-plugins-official 2>&1) || {
        echo "  ! failed to register claude-plugins-official marketplace:"
        echo "$out"
        return 1
    }

    local plugins=(
        pyright-lsp
        claude-md-management
        hookify
        commit-commands
        pr-review-toolkit
        claude-code-setup
        learning-output-style
        ralph-loop
        feature-dev
        frontend-design
        agent-sdk-dev
    )

    for plugin in "${plugins[@]}"; do
        out=$(claude plugin install "${plugin}@claude-plugins-official" 2>&1) || {
            echo "  ! failed to install ${plugin}:"
            echo "$out"
            return 1
        }
        echo "  ✓ ${plugin}"
    done
}

run_gsd_workflow() {
    local out
    # GSD #976: strip context-monitor hook from global settings.json (use auto-compact instead)
    out=$(npx -y get-shit-done-cc --claude --global 2>&1) || { echo "$out"; return 1; }
    echo "$out" | grep -E '^  [⚠✗!]' || true
    out=$(npx -y get-shit-done-cc --codex --global 2>&1) || { echo "$out"; return 1; }
    echo "$out" | grep -E '^  [⚠✗!]' || true

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
    claude-fetch-setup >/dev/null 2>&1 || {
        echo "  ! claude-fetch-setup failed"
        return 1
    }
    echo "  ✓ mcp-fetch"
}

run_codex_statusline() {
    local config_file="$HOME/.codex/config.toml"
    node "$SCRIPT_DIR/lib/ensure-codex-config.js" "$config_file"
    echo "  ✓ codex status line configured"
}
