#!/bin/bash

# Emit the standard GSD codex skill adapter block for a given skill name.
_codex_skill_adapter() {
    local skill_name="$1"
    cat <<ADAPTER
<codex_skill_adapter>
## A. Skill Invocation
- This skill is invoked by mentioning \`\$$skill_name\`.
- Treat all user text after \`\$$skill_name\` as \`{{GSD_ARGS}}\`.
- If no arguments are present, treat \`{{GSD_ARGS}}\` as empty.

## B. AskUserQuestion → request_user_input Mapping
GSD workflows use \`AskUserQuestion\` (Claude Code syntax). Translate to Codex \`request_user_input\`:

Parameter mapping:
- \`header\` → \`header\`
- \`question\` → \`question\`
- Options formatted as \`"Label" — description\` → \`{label: "Label", description: "description"}\`
- Generate \`id\` from header: lowercase, replace spaces with underscores

Batched calls:
- \`AskUserQuestion([q1, q2])\` → single \`request_user_input\` with multiple entries in \`questions[]\`

Multi-select workaround:
- Codex has no \`multiSelect\`. Use sequential single-selects, or present a numbered freeform list asking the user to enter comma-separated numbers.

Execute mode fallback:
- When \`request_user_input\` is rejected (Execute mode), present a plain-text numbered list and pick a reasonable default.

## C. Task() → spawn_agent Mapping
GSD workflows use \`Task(...)\` (Claude Code syntax). Translate to Codex collaboration tools:

Direct mapping:
- \`Task(subagent_type="X", prompt="Y")\` → \`spawn_agent(agent_type="X", message="Y")\`
- \`Task(model="...")\` → omit (Codex uses per-role config, not inline model selection)
- \`fork_context: false\` by default — GSD agents load their own context via \`<files_to_read>\` blocks

Parallel fan-out:
- Spawn multiple agents → collect agent IDs → \`wait(ids)\` for all to complete

Result parsing:
- Look for structured markers in agent output: \`CHECKPOINT\`, \`PLAN COMPLETE\`, \`SUMMARY\`, etc.
- \`close_agent(id)\` after collecting results from each agent
</codex_skill_adapter>
ADAPTER
}

# Sync .claude/commands/*.md from this repo to:
#   ~/.claude/commands/   (Claude Code global commands)
#   ~/.codex/skills/      (Codex skills, if ~/.codex exists)
run_sync_local_commands() {
    local devkit_dir commands_src
    devkit_dir=$(cd "$SCRIPT_DIR/.." && pwd)
    commands_src="$devkit_dir/.claude/commands"

    if [ ! -d "$commands_src" ]; then
        echo "  ! no .claude/commands directory — skipping"
        return 0
    fi

    local claude_dest="$HOME/.claude/commands"
    local codex_dest="$HOME/.codex/skills"
    local synced=0 src_file filename name codex_name description body skill_dir

    mkdir -p "$claude_dest"

    for src_file in "$commands_src"/*.md; do
        [ -f "$src_file" ] || continue

        filename=$(basename "$src_file")
        name="${filename%.md}"
        codex_name="${name//_/-}"

        description=$(awk '/^---/{c++; next} c==1 && /^description:/{sub(/^description:[[:space:]]*/,""); print; exit}' "$src_file")
        body=$(awk 'BEGIN{c=0} /^---/{c++; next} c>=2{print}' "$src_file")

        cp "$src_file" "$claude_dest/$name.md"

        if [ -d "$codex_dest" ]; then
            skill_dir="$codex_dest/$codex_name"
            mkdir -p "$skill_dir"
            {
                printf -- '---\n'
                printf 'name: "%s"\n' "$codex_name"
                printf 'description: "%s"\n' "$description"
                printf 'metadata:\n'
                printf '  short-description: "%s"\n' "$description"
                printf -- '---\n\n'
                _codex_skill_adapter "$codex_name"
                printf '\n'
                printf '%s\n' "$body"
            } > "$skill_dir/SKILL.md"
        fi

        synced=$((synced + 1))
        echo "  synced: $name"
    done

    if [ "$synced" -eq 0 ]; then
        echo "  ! no .md files found in .claude/commands/"
        return 0
    fi

    if [ -d "$codex_dest" ]; then
        echo "  ✓ $synced local command(s) → ~/.claude/commands/ + ~/.codex/skills/"
    else
        echo "  ✓ $synced local command(s) → ~/.claude/commands/"
    fi
}
