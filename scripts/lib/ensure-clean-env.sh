#!/bin/bash

NODE_MIN_MAJOR=20

# Detect which version manager provides the current node.
# Returns: nvm | mise | asdf | volta | fnm | unknown | none
_detect_node_manager() {
    local path="$1"
    if [[ -z "$path" ]]; then
        echo "none"
    elif [[ "$path" == *".nvm"* ]]; then
        echo "nvm"
    elif [[ "$path" == *"mise"* ]]; then
        echo "mise"
    elif [[ "$path" == *".asdf"* ]]; then
        echo "asdf"
    elif [[ "$path" == *".volta"* ]]; then
        echo "volta"
    elif [[ "$path" == *"fnm"* ]]; then
        echo "fnm"
    else
        echo "unknown"
    fi
}

# Check a binary: exists and not duplicated in PATH.
_check_binary() {
    local binary="$1"
    local paths count first
    paths=$(type -a "$binary" 2>/dev/null | sed -n "s/^$binary is //p" || true)
    if [ -z "$paths" ]; then
        count=0
    else
        count=$(echo "$paths" | wc -l | tr -d ' ')
    fi
    first=$(echo "$paths" | head -1)

    if [ "$count" -eq 0 ]; then
        _env_errors+=("$binary not found in PATH.")
        _env_errors+=("  Install $binary and ensure it is in your PATH.")
        return 1
    elif [ "$count" -gt 1 ]; then
        _env_errors+=("Multiple $binary binaries found in PATH:")
        while IFS= read -r p; do
            [ -n "$p" ] && _env_errors+=("  - $p")
        done <<< "$paths"
        _env_errors+=("  Remove duplicates so only one remains.")
        return 1
    fi
    return 0
}

# Print an install/upgrade hint tailored to the detected version manager.
_manager_hint() {
    local action="$1"  # "Install" or "Upgrade"
    local manager="$2"
    case "$manager" in
        nvm)   echo "$action: nvm install --lts" ;;
        mise)  echo "$action: mise use node@lts" ;;
        asdf)  echo "$action: asdf install nodejs latest && asdf local nodejs latest" ;;
        volta) echo "$action: volta install node" ;;
        fnm)   echo "$action: fnm install --lts" ;;
        *)     echo "$action node via your version manager." ;;
    esac
}

ensure_clean_env() {
    _env_errors=()
    _env_warnings=()

    local node_path npm_path
    node_path=$(command -v node 2>/dev/null || true)
    npm_path=$(command -v npm 2>/dev/null || true)

    local manager
    manager=$(_detect_node_manager "$node_path")

    # ── Node ────────────────────────────────────────────────────────────
    if [ -z "$node_path" ]; then
        _env_errors+=("node not found in PATH.")
        _env_errors+=("  $(_manager_hint "Install" "$manager")")
    fi

    # ── npm ─────────────────────────────────────────────────────────────
    if [ -z "$npm_path" ]; then
        _env_errors+=("npm not found in PATH.")
    fi

    # ── Node version ────────────────────────────────────────────────────
    if [ -n "$node_path" ]; then
        local node_major
        node_major=$(node --version 2>/dev/null | sed 's/^v//' | cut -d. -f1)
        if [ -n "$node_major" ] && [ "$node_major" -lt "$NODE_MIN_MAJOR" ]; then
            _env_warnings+=("Node version v$node_major is below recommended minimum (v$NODE_MIN_MAJOR).")
            _env_warnings+=("  $(_manager_hint "Upgrade" "$manager")")
        fi
    fi

    # ── nvm-specific health checks (only when nvm is detected) ──────────
    if [ "$manager" = "nvm" ]; then
        if [ -z "${NVM_DIR:-}" ]; then
            _env_errors+=("NVM_DIR is not set but node appears to be from nvm.")
            _env_errors+=("  Add NVM_DIR to your shell profile.")
        elif [ ! -f "$NVM_DIR/nvm.sh" ]; then
            _env_errors+=("nvm.sh not found at \$NVM_DIR/nvm.sh ($NVM_DIR)")
            _env_errors+=("  Reinstall nvm or fix NVM_DIR in your shell profile.")
        else
            type nvm >/dev/null 2>&1 || source "$NVM_DIR/nvm.sh" 2>/dev/null
            local default_alias
            default_alias=$(nvm alias default 2>/dev/null || true)
            if [[ "$default_alias" == *"N/A"* ]]; then
                _env_errors+=("nvm default alias points to a version that is not installed:")
                _env_errors+=("  $default_alias")
                _env_errors+=("  Fix: nvm alias default 'lts/*'")
            fi
        fi
    fi

    # ── bun ─────────────────────────────────────────────────────────────
    if ! command -v bun >/dev/null 2>&1; then
        _env_errors+=("bun not found in PATH.")
        _env_errors+=("  Install bun: curl -fsSL https://bun.sh/install | bash")
    fi

    # ── CLI tools required by update tasks ──────────────────────────────
    _check_binary "claude"
    _check_binary "codex"

    # ── Root-owned npm global modules ───────────────────────────────────
    if [ -n "$node_path" ]; then
        local npm_prefix npm_modules node_version
        npm_prefix=$(dirname "$(dirname "$node_path")")
        npm_modules="$npm_prefix/lib/node_modules"
        node_version=$(basename "$npm_prefix")

        if [ -d "$npm_modules" ]; then
            local root_owned
            root_owned=$(find "$npm_modules" -maxdepth 2 -user root 2>/dev/null | head -1 || true)
            if [ -n "$root_owned" ]; then
                _env_errors+=("Some npm global modules are owned by root:")
                _env_errors+=("  $root_owned")
                _env_errors+=("")
                _env_errors+=("  This happens when 'sudo npm install -g' was used.")
                _env_errors+=("  Fix permissions: sudo chown -R \$(whoami) $npm_modules")
            fi
        fi
    fi

    # ── Report ──────────────────────────────────────────────────────────
    if [ "${#_env_errors[@]}" -gt 0 ]; then
        echo "══ Environment Pre-Check Failed ══"
        echo ""
        echo "The following issues must be resolved before running update.sh:"
        echo ""
        for err in "${_env_errors[@]}"; do
            echo "$err"
        done
        echo ""
        echo "After fixing these issues, rerun update.sh."
        return 1
    fi

    if [ "${#_env_warnings[@]}" -gt 0 ]; then
        echo "══ Environment Warnings ══"
        echo ""
        for warn in "${_env_warnings[@]}"; do
            echo "$warn"
        done
        echo ""
    fi

    return 0
}
