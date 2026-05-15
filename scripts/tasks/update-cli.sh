#!/bin/bash

# Failure hint for run_global_cli_tools — surfaces the most common npm error
# (ENOTEMPTY when an old global package directory blocks the rename).
print_npm_failure_hint() {
    local log_file="$1"
    local path dest npm_log

    path=$(sed -n 's/^npm error path //p' "$log_file" | tail -1)
    dest=$(sed -n 's/^npm error dest //p' "$log_file" | tail -1)
    npm_log=$(sed -n 's/^npm error A complete log of this run can be found in: //p' "$log_file" | tail -1)

    if grep -q '^npm error ENOTEMPTY: directory not empty, rename ' "$log_file" && [ -n "$dest" ]; then
        echo "  ! npm could not move the existing package out of the way because this path already exists:"
        echo "    $dest"
        if [ -n "$path" ]; then
            echo "  ! It was trying to update:"
            echo "    $path"
        fi
        echo "  ! Inspect that leftover path and, if it is stale, move or remove it manually, then rerun update.sh."
        echo "  ! Example:"
        echo "    ls -la \"$(dirname "$dest")\""
        echo "    mv \"$dest\" \"${dest}.bak.$(date +%Y%m%d_%H%M%S)\""
    fi

    if [ -n "$npm_log" ]; then
        echo "  ! npm log: $npm_log"
    fi
}

run_global_cli_tools() {
    # Keep all global npm installs in one command so they do not race on the same prefix.
    npm install -g --loglevel=error \
        @anthropic-ai/claude-code \
        claude-fetch-setup \
        @openai/codex \
        pyright

    echo "  ✓ claude $(claude --version 2>/dev/null)"
    echo "  ✓ codex $(codex --version 2>/dev/null)"
    echo "  ✓ pyright $(pyright --version 2>/dev/null)"
}

prune_broken_codex_skill_symlinks() {
    local skills_dir="$HOME/.codex/skills"
    local link removed=0

    [ -d "$skills_dir" ] || return 0

    while IFS= read -r -d '' link; do
        rm -f "$link"
        removed=$((removed + 1))
    done < <(find "$skills_dir" -xtype l -print0 2>/dev/null)

    if [ "$removed" -gt 0 ]; then
        echo "  ! removed $removed broken Codex skill symlink(s)"
    fi
}

prune_gsd_hooks() {
    local config_dir="$1"
    local label="$2"
    local hooks_dir="$config_dir/hooks"
    local hook removed=0

    [ -d "$hooks_dir" ] || return 0

    while IFS= read -r -d '' hook; do
        rm -f "$hook"
        removed=$((removed + 1))
    done < <(find "$hooks_dir" -maxdepth 1 -type f \( -name 'gsd-*.js' -o -name 'gsd-*.sh' \) -print0 2>/dev/null)

    if [ "$removed" -gt 0 ]; then
        echo "  ! removed $removed $label GSD hook file(s) before retry"
    fi
}

run_gsd_installer() {
    local label="$1"
    local config_dir="$2"
    shift 2

    local out
    if out=$(npx -y get-shit-done-cc "$@" 2>&1); then
        echo "$out" | grep -E '^  [⚠✗!]' || true
        return 0
    fi

    if echo "$out" | grep -q 'installer migration blocked pending user choice' &&
        echo "$out" | grep -q 'hooks/gsd-'; then
        prune_gsd_hooks "$config_dir" "$label"
        out=$(npx -y get-shit-done-cc "$@" 2>&1) || { echo "$out"; return 1; }
        echo "$out" | grep -E '^  [⚠✗!]' || true
        return 0
    fi

    echo "$out"
    return 1
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
    # GSD #976: strip context-monitor hook from global settings.json (use auto-compact instead)
    run_gsd_installer "Claude Code" "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" --claude --global || return 1
    prune_broken_codex_skill_symlinks
    run_gsd_installer "Codex" "${CODEX_HOME:-$HOME/.codex}" --codex --global || return 1

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

run_codex_config() {
    local config_file="$HOME/.codex/config.toml"

    if command -v codex >/dev/null 2>&1; then
        codex features enable goals >/dev/null
        codex features enable hooks >/dev/null
        echo "  ✓ codex features enabled: goals, hooks"
    else
        echo "  ! skipped codex feature setup because codex is not installed"
    fi

    bun "$SCRIPT_DIR/lib/ensure-codex-config.ts" "$config_file"
    echo "  ✓ codex status line configured"
}
