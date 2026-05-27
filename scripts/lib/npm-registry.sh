#!/bin/bash

NPM_MIRROR_REGISTRY="${NPM_MIRROR_REGISTRY:-https://registry.npmmirror.com}"
NPM_FALLBACK_REGISTRY="${NPM_FALLBACK_REGISTRY:-https://registry.npmjs.org}"
NPM_REGISTRY_MODE="${NPM_REGISTRY_MODE:-mirror-first}"

npm_package_available() {
    local package="$1"
    local registry="$2"

    npm_package_version "$package" "$registry" >/dev/null 2>&1
}

npm_package_version() {
    local package="$1"
    local registry="$2"

    npm view "$package" version --registry="$registry" 2>/dev/null | tail -1
}

global_npm_package_version() {
    local package="$1"
    local tree

    tree=$(npm ls -g "$package" --json --depth=10 2>/dev/null) || true
    [ -n "$tree" ] || return 1

    PACKAGE_NAME="$package" node -e '
const target = process.env.PACKAGE_NAME
let root

try {
  root = JSON.parse(require("fs").readFileSync(0, "utf8"))
} catch {
  process.exit(1)
}

function findPackage(node, name) {
  if (!node?.dependencies) return null

  for (const [depName, dep] of Object.entries(node.dependencies)) {
    if (depName === name && dep?.version) return dep.version

    const nested = findPackage(dep, name)
    if (nested) return nested
  }

  return null
}

const version = findPackage(root, target)
if (!version) process.exit(1)
console.log(version)
' <<< "$tree"
}

select_npm_registry() {
    local purpose="$1"
    shift

    if [ "$NPM_REGISTRY_MODE" = "direct" ]; then
        for package in "$@"; do
            if ! npm_package_available "$package" "$NPM_FALLBACK_REGISTRY"; then
                echo "  ! $purpose package unavailable from npm registry: $package" >&2
                return 1
            fi
        done

        echo "  ✓ $purpose registry: $NPM_FALLBACK_REGISTRY (--no-npm-mirror)" >&2
        printf '%s\n' "$NPM_FALLBACK_REGISTRY"
        return 0
    fi

    local package missing=()
    for package in "$@"; do
        if ! npm_package_available "$package" "$NPM_MIRROR_REGISTRY"; then
            missing+=("$package")
        fi
    done

    if [ "${#missing[@]}" -eq 0 ]; then
        echo "  ✓ $purpose registry: $NPM_MIRROR_REGISTRY" >&2
        printf '%s\n' "$NPM_MIRROR_REGISTRY"
        return 0
    fi

    echo "  ! $purpose mirror missing package(s): ${missing[*]}" >&2
    echo "  ! falling back to $NPM_FALLBACK_REGISTRY" >&2

    for package in "$@"; do
        if ! npm_package_available "$package" "$NPM_FALLBACK_REGISTRY"; then
            echo "  ! $purpose package unavailable from fallback registry: $package" >&2
            return 1
        fi
    done

    printf '%s\n' "$NPM_FALLBACK_REGISTRY"
}

claude_native_package() {
    node - <<'NODE'
function detectMusl() {
  if (process.platform !== 'linux') return false
  const report =
    typeof process.report?.getReport === 'function'
      ? process.report.getReport()
      : null
  return report != null && report.header?.glibcVersionRuntime === undefined
}

const cpu = process.arch
let platformKey = null

if (process.platform === 'linux') {
  platformKey = `linux-${cpu}${detectMusl() ? '-musl' : ''}`
} else if (process.platform === 'darwin') {
  platformKey = `darwin-${cpu}`
} else if (process.platform === 'win32') {
  platformKey = `win32-${cpu}`
}

if (platformKey) {
  console.log(`@anthropic-ai/claude-code-${platformKey}`)
}
NODE
}
