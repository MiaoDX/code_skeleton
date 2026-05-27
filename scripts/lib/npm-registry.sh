#!/bin/bash

NPM_MIRROR_REGISTRY="${NPM_MIRROR_REGISTRY:-https://registry.npmmirror.com}"
NPM_FALLBACK_REGISTRY="${NPM_FALLBACK_REGISTRY:-https://registry.npmjs.org}"
NPM_REGISTRY_MODE="${NPM_REGISTRY_MODE:-mirror-first}"

npm_registry_notice() {
    local message="$*"

    if declare -F task_notice >/dev/null 2>&1; then
        task_notice "$message"
    elif [[ "${TASK_NOTICE_FD:-}" =~ ^[0-9]+$ ]]; then
        printf '  → %s\n' "$message" >&"$TASK_NOTICE_FD" 2>/dev/null || true
    fi
}

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

npm_package_field_json() {
    local package="$1"
    local field="$2"
    local registry="$3"

    npm view "$package" "$field" --json --registry="$registry" 2>/dev/null
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

codex_native_package_name() {
    node - <<'NODE'
const cpu = process.arch
let platformKey = null

if (process.platform === 'linux') {
  platformKey = `linux-${cpu}`
} else if (process.platform === 'darwin') {
  platformKey = `darwin-${cpu}`
} else if (process.platform === 'win32') {
  platformKey = `win32-${cpu}`
}

if (platformKey) {
  console.log(`@openai/codex-${platformKey}`)
}
NODE
}

codex_native_package_available() {
    local registry="$1"
    local codex_version native_name optional_dependencies native_spec native_version tag_value

    native_name=$(codex_native_package_name)
    [ -n "$native_name" ] || return 0

    codex_version=$(npm_package_version @openai/codex "$registry") || return 1
    [ -n "$codex_version" ] || return 1

    optional_dependencies=$(npm_package_field_json "@openai/codex@$codex_version" optionalDependencies "$registry") || return 1
    native_spec=$(NATIVE_NAME="$native_name" node -e '
const nativeName = process.env.NATIVE_NAME
let optionalDependencies

try {
  optionalDependencies = JSON.parse(require("fs").readFileSync(0, "utf8"))
} catch {
  process.exit(1)
}

const spec = optionalDependencies?.[nativeName]
if (!spec) process.exit(1)
console.log(spec)
' <<< "$optional_dependencies") || return 1

    native_version="${native_spec#npm:@openai/codex@}"
    [ "$native_version" != "$native_spec" ] || return 1

    tag_value=$(npm_package_field_json @openai/codex dist-tags "$registry" | NATIVE_NAME="$native_name" node -e '
const nativeName = process.env.NATIVE_NAME
const tag = nativeName.replace("@openai/codex-", "")
let distTags

try {
  distTags = JSON.parse(require("fs").readFileSync(0, "utf8"))
} catch {
  process.exit(1)
}

const version = distTags?.[tag]
if (!version) process.exit(1)
console.log(version)
') || return 1

    [ "$tag_value" = "$native_version" ]
}

npm_registry_has_required_native_packages() {
    local registry="$1"
    shift

    local package
    for package in "$@"; do
        if [ "$package" = "@openai/codex" ] && ! codex_native_package_available "$registry"; then
            echo "  ! Codex native package is unavailable from registry: $registry" >&2
            return 1
        fi
    done
}

select_npm_registry() {
    local purpose="$1"
    shift

    if [ "$NPM_REGISTRY_MODE" = "direct" ]; then
        npm_registry_notice "$purpose: checking npm registry $NPM_FALLBACK_REGISTRY"
        for package in "$@"; do
            if ! npm_package_available "$package" "$NPM_FALLBACK_REGISTRY"; then
                echo "  ! $purpose package unavailable from npm registry: $package" >&2
                return 1
            fi
        done

        npm_registry_has_required_native_packages "$NPM_FALLBACK_REGISTRY" "$@" || return 1

        npm_registry_notice "$purpose: using npm registry $NPM_FALLBACK_REGISTRY"
        echo "  ✓ $purpose registry: $NPM_FALLBACK_REGISTRY (--no-npm-mirror)" >&2
        printf '%s\n' "$NPM_FALLBACK_REGISTRY"
        return 0
    fi

    local package missing=()
    npm_registry_notice "$purpose: checking npm mirror $NPM_MIRROR_REGISTRY"
    for package in "$@"; do
        if ! npm_package_available "$package" "$NPM_MIRROR_REGISTRY"; then
            missing+=("$package")
        fi
    done

    if [ "${#missing[@]}" -eq 0 ] && npm_registry_has_required_native_packages "$NPM_MIRROR_REGISTRY" "$@"; then
        npm_registry_notice "$purpose: using npm mirror $NPM_MIRROR_REGISTRY"
        echo "  ✓ $purpose registry: $NPM_MIRROR_REGISTRY" >&2
        printf '%s\n' "$NPM_MIRROR_REGISTRY"
        return 0
    fi

    if [ "${#missing[@]}" -gt 0 ]; then
        npm_registry_notice "$purpose: mirror missing ${missing[*]}; checking fallback $NPM_FALLBACK_REGISTRY"
        echo "  ! $purpose mirror missing package(s): ${missing[*]}" >&2
    else
        npm_registry_notice "$purpose: mirror missing required native package; checking fallback $NPM_FALLBACK_REGISTRY"
        echo "  ! $purpose mirror missing required native package(s)" >&2
    fi
    echo "  ! falling back to $NPM_FALLBACK_REGISTRY" >&2

    for package in "$@"; do
        if ! npm_package_available "$package" "$NPM_FALLBACK_REGISTRY"; then
            echo "  ! $purpose package unavailable from fallback registry: $package" >&2
            return 1
        fi
    done
    npm_registry_has_required_native_packages "$NPM_FALLBACK_REGISTRY" "$@" || return 1

    npm_registry_notice "$purpose: using fallback registry $NPM_FALLBACK_REGISTRY"
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
