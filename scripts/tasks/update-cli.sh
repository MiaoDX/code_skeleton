#!/bin/bash

_TASK_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$_TASK_DIR/../lib/npm-registry.sh"
unset _TASK_DIR

if ! declare -F task_notice >/dev/null 2>&1; then
    task_notice() { :; }
fi

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

print_tool_version() {
    local label="$1"
    local binary="$2"
    local version

    version=$("$binary" --version 2>&1) || {
        echo "  ! $label failed after install:"
        echo "$version"
        return 1
    }

    echo "  ✓ $label $version"
}

global_cli_packages_current() {
    local registry="$1"
    shift

    local package latest installed all_current=true
    for package in "$@"; do
        task_notice "Global CLI tools: checking $package"
        latest=$(npm_package_version "$package" "$registry") || latest=""
        installed=$(global_npm_package_version "$package") || installed=""

        if [ -z "$installed" ]; then
            echo "  ! missing global package: $package@$latest"
            all_current=false
        elif [ -z "$latest" ]; then
            echo "  ! could not resolve latest version for: $package"
            all_current=false
        elif [ "$installed" != "$latest" ]; then
            echo "  ! global package update available: $package $installed → $latest"
            all_current=false
        fi
    done

    local codex_native_name codex_native_version codex_native_installed
    codex_native_name=$(codex_native_package_name)
    if [ -n "$codex_native_name" ]; then
        codex_native_version=$(codex_native_package_version "$registry") || codex_native_version=""
        codex_native_installed=$(global_npm_package_version "$codex_native_name") || codex_native_installed=""

        if [ -z "$codex_native_version" ]; then
            echo "  ! could not resolve Codex native package version for: $codex_native_name"
            all_current=false
        elif [ -z "$codex_native_installed" ]; then
            echo "  ! missing global package: $codex_native_name@$codex_native_version"
            all_current=false
        elif [ "$codex_native_installed" != "$codex_native_version" ]; then
            echo "  ! global package update available: $codex_native_name $codex_native_installed → $codex_native_version"
            all_current=false
        fi
    fi

    if $all_current; then
        echo "  ✓ global CLI packages already current"
        return 0
    fi

    return 1
}

run_global_cli_tools() {
    local packages=(
        @anthropic-ai/claude-code
        claude-fetch-setup
        @openai/codex
        pyright
    )
    local native_package
    native_package=$(claude_native_package)
    if [ -n "$native_package" ]; then
        packages+=("$native_package")
    fi

    local registry
    registry=$(select_npm_registry "Global CLI tools" "${packages[@]}") || return 1

    task_notice "Global CLI tools: checking installed versions"
    if global_cli_packages_current "$registry" "${packages[@]}"; then
        print_tool_version claude claude
        print_tool_version codex codex
        print_tool_version pyright pyright
        return 0
    fi

    # Keep all global npm installs in one command so they do not race on the same prefix.
    local install_packages=(
        @anthropic-ai/claude-code
        claude-fetch-setup
        @openai/codex
        pyright
    )
    local codex_native_version
    local codex_native_name
    codex_native_version=$(codex_native_package_version "$registry") || codex_native_version=""
    codex_native_name=$(codex_native_package_name)
    if [ -n "$codex_native_name" ] && [ -n "$codex_native_version" ]; then
        install_packages+=("$codex_native_name@npm:@openai/codex@$codex_native_version")
    fi

    task_notice "Global CLI tools: installing ${install_packages[*]} via $registry"
    npm install -g --loglevel=error --include=optional --foreground-scripts --registry="$registry" "${install_packages[@]}"

    print_tool_version claude claude
    print_tool_version codex codex
    print_tool_version pyright pyright
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
        echo "  ! removed $removed existing $label GSD hook file(s)"
    fi
}

run_claude_plugins() {
    local out

    task_notice "Claude plugins: registering marketplace"
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
        task_notice "Claude plugins: installing $plugin"
        out=$(claude plugin install "${plugin}@claude-plugins-official" 2>&1) || {
            echo "  ! failed to install ${plugin}:"
            echo "$out"
            return 1
        }
        echo "  ✓ ${plugin}"
    done
}

gsd_current_for_target() {
    local label="$1"
    local config_dir="$2"
    local latest="$3"
    local version_file="$config_dir/get-shit-done/VERSION"
    local installed=""

    if [ -f "$version_file" ]; then
        installed=$(cat "$version_file")
    fi

    if [ "$installed" = "$latest" ]; then
        echo "  ✓ gsd $label already current: v$installed"
        return 0
    fi

    if [ -z "$installed" ]; then
        echo "  ! gsd $label missing; installing v$latest"
    else
        echo "  ! gsd $label update available: v$installed → v$latest"
    fi

    return 1
}

run_gsd_installer() {
    local registry="$1"
    local target="$2"
    local out

    task_notice "GSD workflow: running installer $target via $registry"
    out=$(npx --registry="$registry" -y @opengsd/get-shit-done-redux "$target" --global 2>&1) || { echo "$out"; return 1; }
    echo "$out" | grep -E '^  [⚠✗!]' || true
}

run_gsd_workflow() {
    local registry
    local latest
    registry=$(select_npm_registry "GSD workflow" @opengsd/get-shit-done-redux) || return 1
    task_notice "GSD workflow: resolving latest version"
    latest=$(npm_package_version @opengsd/get-shit-done-redux "$registry") || return 1

    task_notice "GSD workflow: checking Claude install"
    # GSD #976: strip context-monitor hook from global settings.json (use auto-compact instead)
    prune_gsd_hooks "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" "Claude Code"
    if ! gsd_current_for_target "claude" "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" "$latest"; then
        run_gsd_installer "$registry" --claude || return 1
    fi

    task_notice "GSD workflow: checking Codex install"
    prune_broken_codex_skill_symlinks
    prune_gsd_hooks "${CODEX_HOME:-$HOME/.codex}" "Codex"
    if ! gsd_current_for_target "codex" "${CODEX_HOME:-$HOME/.codex}" "$latest"; then
        run_gsd_installer "$registry" --codex || return 1
    fi

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
    task_notice "MCP: fetch: running claude-fetch-setup"
    claude-fetch-setup >/dev/null 2>&1 || {
        echo "  ! claude-fetch-setup failed"
        return 1
    }
    echo "  ✓ mcp-fetch"
}

run_codex_config() {
    local config_file="$HOME/.codex/config.toml"

    if command -v codex >/dev/null 2>&1; then
        task_notice "Codex config: enabling features"
        codex features enable goals >/dev/null
        codex features enable hooks >/dev/null
        echo "  ✓ codex features enabled: goals, hooks"
    else
        echo "  ! skipped codex feature setup because codex is not installed"
    fi

    task_notice "Codex config: writing status line"
    bun "$SCRIPT_DIR/lib/ensure-codex-config.ts" "$config_file"
    echo "  ✓ codex status line configured"
}
