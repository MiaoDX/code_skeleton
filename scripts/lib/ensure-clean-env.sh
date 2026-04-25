#!/bin/bash

NODE_MIN_MAJOR=20

# type -a is portable in bash and resolves shell functions/aliases
_check_nvm_binary() {
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
        return 0
    elif [ "$count" -gt 1 ]; then
        _env_errors+=("Multiple $binary binaries found in PATH:")
        while IFS= read -r p; do
            [ -n "$p" ] && _env_errors+=("  - $p")
        done <<< "$paths"
        _env_errors+=("  Remove duplicates so only the nvm npm global install remains.")
    elif [[ "$first" != *".nvm"* ]]; then
        _env_errors+=("$binary is not installed via nvm npm: $first")
        _env_errors+=("  Remove this installation. update.sh will install via npm.")
    fi
}

ensure_clean_env() {
    _env_errors=()
    _env_warnings=()

    # nvm is a shell function, not a binary — check NVM_DIR and nvm.sh
    if [ -z "${NVM_DIR:-}" ]; then
        _env_errors+=("NVM_DIR is not set. nvm does not appear to be installed.")
        _env_errors+=("  Install nvm: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash")
        _env_errors+=("  Then restart your shell.")
    elif [ ! -f "$NVM_DIR/nvm.sh" ]; then
        _env_errors+=("nvm.sh not found at \$NVM_DIR/nvm.sh")
        _env_errors+=("  NVM_DIR is set to: $NVM_DIR")
        _env_errors+=("  Reinstall nvm or fix NVM_DIR in your shell profile.")
    fi

    if [ -n "${NVM_DIR:-}" ] && [ -f "$NVM_DIR/nvm.sh" ]; then
        type nvm >/dev/null 2>&1 || source "$NVM_DIR/nvm.sh" 2>/dev/null
        local default_alias
        default_alias=$(nvm alias default 2>/dev/null || true)
        if [[ "$default_alias" == *"N/A"* ]]; then
            _env_errors+=("nvm default alias points to a version that is not installed:")
            _env_errors+=("  $default_alias")
            _env_errors+=("")
            _env_errors+=("  Fix by setting default to latest LTS:")
            _env_errors+=("    nvm alias default 'lts/*'")
        fi
    fi

    local node_path npm_path
    node_path=$(command -v node 2>/dev/null || true)
    npm_path=$(command -v npm 2>/dev/null || true)

    if [ -z "$node_path" ]; then
        _env_errors+=("node not found in PATH.")
        _env_errors+=("  Install a node version via nvm: nvm install --lts")
    elif [[ "$node_path" != *".nvm"* ]]; then
        _env_errors+=("node is not provided by nvm: $node_path")
        _env_errors+=("  Remove or unlink non-nvm node installations and use nvm instead.")
    fi

    if [ -z "$npm_path" ]; then
        _env_errors+=("npm not found in PATH.")
    elif [[ "$npm_path" != *".nvm"* ]]; then
        _env_errors+=("npm is not provided by nvm: $npm_path")
        _env_errors+=("  Remove or unlink non-nvm npm installations.")
    fi

    if [ -n "$node_path" ]; then
        local node_major
        node_major=$(node --version 2>/dev/null | sed 's/^v//' | cut -d. -f1)
        if [ -n "$node_major" ] && [ "$node_major" -lt "$NODE_MIN_MAJOR" ]; then
            _env_warnings+=("Node version v$node_major is outdated (minimum recommended: v$NODE_MIN_MAJOR).")
            _env_warnings+=("  Consider upgrading: nvm install --lts && nvm use --lts")
        fi
    fi

    if ! command -v bun >/dev/null 2>&1; then
        _env_errors+=("bun not found in PATH.")
        _env_errors+=("  Install bun: curl -fsSL https://bun.sh/install | bash")
    fi

    _check_nvm_binary "claude"
    _check_nvm_binary "codex"

    if [ -n "$node_path" ]; then
        local npm_prefix npm_modules node_version
        npm_prefix=$(dirname "$(dirname "$node_path")")
        npm_modules="$npm_prefix/lib/node_modules"
        node_version=$(basename "$npm_prefix")

        if [ -d "$npm_modules" ]; then
            local root_owned
            root_owned=$(find "$npm_modules" -maxdepth 2 -user root 2>/dev/null | head -1 || true)
            if [ -n "$root_owned" ]; then
                # Root-owned files mean "sudo npm install -g" was used — with nvm, sudo is never needed
                _env_errors+=("Some npm global modules are owned by root:")
                _env_errors+=("  $root_owned")
                _env_errors+=("")
                _env_errors+=("  This happens when 'sudo npm install -g' was used. With nvm, sudo is never needed.")
                _env_errors+=("")
                _env_errors+=("  Recommended - Switch to latest LTS (clean slate, update.sh re-installs everything):")
                _env_errors+=("    nvm install --lts && nvm uninstall $node_version && nvm use --lts")
                _env_errors+=("")
                _env_errors+=("  Not recommended - Fix permissions only (quick but doesn't address root cause):")
                _env_errors+=("    sudo chown -R \$(whoami):staff $npm_modules")
            fi
        fi
    fi

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
