---
name: intuitive-init
description: Initialize, audit, aggressively slim, merge, and refresh project-local AGENTS.md and CLAUDE.md files from existing repo guidance, agent /init suggestions, stdin-bundled Codex init-style discovery, and intuitive workflow defaults. Use when setting up a repo for Claude Code/Codex, replacing symlinked agent files with local guidance, rerunning agent init after weeks of drift, cleaning overgrown root agent files, or aligning a repo to intuitive-doc, intuitive-layout, intuitive-tests, intuitive-flow, and intuitive-refactor without overwriting project-specific hints.
---

# Intuitive Init

Set up repo-local AI agent guidance without turning shared defaults into a
symlinked source of truth. Shared skills should travel across projects;
`AGENTS.md` and `CLAUDE.md` should preserve the local repo's commands,
constraints, workflow choices, and hard-won mistakes.

Default posture: keep root agent files aggressively small. Correct but lengthy
procedures should usually move out of `AGENTS.md` and `CLAUDE.md` into
`docs/agents/**`, reusable skills, or scripts, with the root files keeping only
the rule, trigger, and pointer.

Use these size signals:

- Target: each root agent file is short enough to skim before work starts,
  usually under 120 lines.
- Warning: over 180 lines means audit should report bloat and propose deletes or
  extraction.
- Strong cleanup signal: over 250 lines, duplicated sections between
  `AGENTS.md` and `CLAUDE.md`, or long numbered procedures in root files.

These are signals, not hard limits. Keep a longer root file only when the
content is a critical safety rule that agents must see before any other read.

## Human/Agent Documentation Boundary

`AGENTS.md` and `CLAUDE.md` are agent-operational docs. Human-facing project
truth belongs in `README.md`, `ARCHITECTURE.md`, `STATUS.md`, and
`docs/human/**` unless a repo explicitly declares a different human surface.

Agent files may point to human-authoritative docs and say how agents should
react when those docs conflict with a request. Do not copy milestone goals,
non-goals, steering policy, documentation taxonomy, or other human-facing
project state into agent files. Those copied blocks drift after `$intuitive-doc`
cleans or reorganizes the human surface.

## Agent Reference File Boundary

Use `docs/agents/**` for repo-specific agent reference material that is too long
for the root files but still useful to coding agents.

Good candidates for `docs/agents/**`:

- release procedures
- CI failure investigation runbooks
- dependency/bootstrap playbooks
- GPU, simulator, cloud, or hardware setup notes
- PR review/fix workflows
- model/tool-specific caveats
- long examples and copy/paste command checklists

Prefer a reusable skill when the procedure applies across repos. Prefer a
script, Makefile target, or just recipe when the procedure is mostly commands.
Prefer human docs when the information is project truth for humans, not agent
operation.

Root `AGENTS.md` and `CLAUDE.md` should contain only:

- the first docs to read
- critical local hazards and permissions
- canonical install/test/verify commands or the pointer to them
- source-of-truth boundaries
- short skill routing
- pointers to longer `docs/agents/**` runbooks when needed

## Core Rule

Treat generated init output and Intuitive Flow defaults as reviewers, not
authority.

Authoritative inputs, in order:

1. System/developer/user instructions for the current session.
2. Existing project-local `AGENTS.md` and `CLAUDE.md`.
3. Root orientation docs such as `README.md`, `ARCHITECTURE.md`, `STATUS.md`,
   `docs/agents/**`, and command docs.
4. Actual repo commands, scripts, package metadata, CI config, and tests.
5. Agent `/init` suggestions or stdin-bundled init-style discovery from a
   read-only Codex run.
6. Intuitive Flow defaults and skill-routing conventions.

## Default Workflow

Use this workflow unless the user asks for report-only or a specific file.

1. Read the repo orientation surface:
   - `README.md`
   - `ARCHITECTURE.md` and `STATUS.md` when present
   - existing `AGENTS.md` and `CLAUDE.md`
   - nearby agent docs such as `docs/agents/**` when present
2. Inspect the files, commands, and config that make guidance testable:
   - package metadata
   - `justfile`, `Makefile`, scripts, CI workflows, test config
   - skill folders or command folders
3. Run agent-init discovery by default when available:
   - Use `/init` or the tool's equivalent in suggestion/refactor mode.
   - If `/init` refuses because `AGENTS.md` or `CLAUDE.md` already exists,
     prompt it to "help refactor the current file" rather than overwrite.
   - Capture useful suggestions only. Do not treat init output as final text.
   - If native slash commands are not exposed in the current interface, use the
     stdin-bundled Codex CLI discovery below before continuing from repo
     evidence alone.
4. Classify current guidance:
   - **Preserve**: project commands, env setup, permissions, local hazards,
     workflow source-of-truth rules, domain vocabulary, test gates.
   - **Merge**: concise shared behavior that still fits this repo.
   - **Replace**: stale setup steps, symlink-first instructions for root agent
     files, generic advice duplicated by system behavior.
   - **Extract**: correct but lengthy procedures that belong in
     `docs/agents/**`, a reusable skill, or a script instead of root guidance.
   - **Collapse**: verbose but necessary root guidance that can become one rule
     plus a pointer.
   - **Remove**: obsolete commands, absolute paths from another project,
     generic best practices, duplicated Claude/Codex sections, copied human
     project state, or process notes that belong in skills instead of root
     guidance.
5. Add or refresh a short preferred-skills block when relevant:
   - `$intuitive-init` for agent guidance initialization and periodic refresh.
   - `$intuitive-doc` for human-facing docs and doc drift.
   - `$intuitive-layout` for repo/folder organization.
   - `$intuitive-tests` for test-suite structure and behavior-focused cleanup.
   - `$intuitive-flow` for fuzzy idea to planned execution.
   - `$intuitive-refactor` before broad architecture or refactor work.
   - `$intuitive-squash` for cleaning local agent commit history before handoff.
   Keep this block as routing guidance only. Do not use it to define the human
   documentation surface; `$intuitive-doc` owns that split.
6. Produce a merged proposal first:
   - Summarize the source inputs used.
   - Report root file sizes and whether cleanup pressure is low, medium, or
     high.
   - Explain what was preserved, collapsed, extracted, replaced, and removed.
   - Name any new `docs/agents/**`, skill, script, or human-doc destination for
     extracted content.
   - Show the diff or proposed file contents.
7. Apply changes only when the user has asked for direct implementation or
   approves the proposal. When applying, update both `AGENTS.md` and
   `CLAUDE.md` if both exist and the rule applies to both agents.

## Agent-Init Discovery

Use this order so the skill benefits from init-style review without depending
on nested sandbox support.

### Native slash command

Use this when the host exposes `/init` or an equivalent tool:

```text
/init
```

If root agent files already exist, ask for suggestion/refactor mode rather than
overwrite mode:

```text
Help refactor the current AGENTS.md and CLAUDE.md. Produce suggestions only;
do not overwrite files.
```

### Default Codex CLI discovery

Use this when native `/init` is not exposed but the `codex` CLI is installed.
This is not a file-editing pass. It is a second-opinion reviewer that should
only produce suggestions to merge into the proposal. Build a context bundle
with the host tools and pipe it into Codex so Codex does not need to run nested
read commands through its own sandbox.

Run from the repository root:

```bash
{
  printf '# AGENTS.md\n'
  sed -n '1,260p' AGENTS.md 2>/dev/null || true
  printf '\n# CLAUDE.md\n'
  sed -n '1,260p' CLAUDE.md 2>/dev/null || true
  printf '\n# pyproject.toml selected sections\n'
  awk '
    /^\[project.optional-dependencies\]/ {p=1}
    /^\[tool.pytest.ini_options\]/ {p=1}
    /^\[tool.coverage.run\]/ {p=1}
    /^\[/ && !/^\[project.optional-dependencies\]/ && !/^\[tool.pytest.ini_options\]/ && !/^\[tool.coverage.run\]/ {if (p) p=0}
    p {print}
  ' pyproject.toml 2>/dev/null || true
  printf '\n# Orientation and automation files present\n'
  rg --files -g 'README.md' -g 'ARCHITECTURE.md' -g 'STATUS.md' -g 'Makefile' -g 'justfile' -g '.github/workflows/*.yml' -g '.github/workflows/*.yaml' -g 'docs/agents/**' 2>/dev/null | sort || true
} | codex --ask-for-approval never exec --ephemeral --skip-git-repo-check --sandbox read-only -C "$PWD" \
  "Act like Codex /init in suggestion-only mode for this repository. Analyze only the context bundle provided on stdin; do not run shell commands and do not edit files. Prefer aggressively small root agent files. Return: source inputs inspected, root file bloat signals, project-specific guidance to preserve, correct-but-lengthy guidance to extract into docs/agents/** or skills/scripts, stale or duplicated guidance to remove, missing operational rules, and concise suggested edits for AGENTS.md and CLAUDE.md."
```

If the host does not support `--ephemeral`, remove that flag.

### Optional direct Codex read

Only use this when the environment is known to support Codex's nested read-only
sandbox. It may fail on ordinary hosts that restrict bubblewrap user or network
namespaces.

```bash
codex --ask-for-approval never exec --ephemeral --skip-git-repo-check --sandbox read-only -C "$PWD" \
  "Act like Codex /init in suggestion-only mode for this repository. Read the local orientation, agent, package, test, and CI files. Do not edit files. Prefer aggressively small root agent files. Return: source inputs inspected, root file bloat signals, project-specific guidance to preserve, correct-but-lengthy guidance to extract into docs/agents/** or skills/scripts, stale or duplicated guidance to remove, missing operational rules, and concise suggested edits for AGENTS.md and CLAUDE.md. Do not propose a full replacement unless the current files are unusable or overgrown enough that a thin-root rebuild is safer than patching."
```

Treat the output as advisory. If it conflicts with repo evidence, preserve the
repo evidence and mention the disagreement in the proposal.

If `codex` is missing, exits non-zero, or the environment cannot run external
agents, say so briefly and continue from repo evidence.

## Modes

### Audit

Use when the user asks what should change, or when broad edits would be risky.

Report:

```text
Agent files:
Init discovery:
Root file size / cleanup pressure:
Project-specific guidance to preserve:
Correct but lengthy guidance to extract:
Shared boilerplate to remove:
Missing preferred-skill routing:
Suggested edits:
Apply now? <yes/no needed unless already authorized>
```

Audit must name deletion and extraction candidates. Do not stop at "preserve"
just because a section is true. If the section is true but too long for root
guidance, classify it as Extract or Collapse.

### Apply

Use when the user explicitly asks to update the repo guidance.

Steps:

1. Run the default workflow.
2. Edit only `AGENTS.md`, `CLAUDE.md`, and directly related init docs/scripts
   the user named.
3. Keep the files self-contained for critical startup rules, but allow pointers
   to `docs/agents/**` for long operational procedures.
4. Create or update `docs/agents/**` only for extracted agent runbooks that are
   too long for the root files and are not human-facing project truth.
5. Preserve differences between Claude and Codex when they matter.
6. Search for stale setup/init claims after editing.

### Refresh

Use after several weeks, major command changes, a new subsystem, repeated agent
mistakes, or a changed planning workflow.

Run the same workflow as Apply, but be stricter about removing stale commands
and softer about adding new process. A refresh should reduce drift, not expand
root guidance into a manual.

Also use Refresh after `$intuitive-doc` has created, moved, or clarified the
human documentation surface. In that case, update agent files to point at the
final surface and remove copied project strategy, milestone state, or doc-tier
policy that now belongs in human docs.

Refresh is allowed and expected to delete root guidance that is obsolete,
duplicated, generic, copied from human docs, or correct-but-better-extracted.
When the root files are over the strong cleanup signal, prefer a thin-root
rewrite over a patchwork edit: rebuild `AGENTS.md` and `CLAUDE.md` from the
preserve list, then move long runbooks into `docs/agents/**`.

### Slim / Cleanup

Use when the user says the root agent files are too long, asks for aggressive
cleanup, asks to make them "as clean as possible", or when audit finds strong
cleanup signals.

Default result:

- `AGENTS.md`: repo-wide rules all agents must see immediately.
- `CLAUDE.md`: Claude-specific deltas only, not a full duplicate of
  `AGENTS.md`.
- `docs/agents/README.md`: index of longer agent-only runbooks when any exist.
- `docs/agents/<topic>.md`: extracted procedures for release, CI triage,
  environment setup, GPU/simulator setup, PR workflows, or similar long tasks.

Steps:

1. Build a preserve list from actual repo evidence.
2. Mark each current root section as Preserve, Collapse, Extract, Remove, or
   Human-doc drift.
3. Draft the thin root files first.
4. Draft extracted `docs/agents/**` runbooks only for procedures that remain
   useful.
5. Verify root files contain pointers to extracted runbooks and no long copied
   procedures.
6. Show the deletion/extraction diff unless the user already approved applying.

### Symlink Migration

Use when `AGENTS.md` or `CLAUDE.md` is a symlink to a shared toolkit.

Preferred result:

- Convert the symlink into a project-local regular file.
- Preserve the current linked content as the starting point.
- Merge in project-specific hints from repo evidence and init suggestions.
- Keep reusable workflows in skills, not pasted into the root files.

Do not silently overwrite local agent files with shared templates. If a legacy
bootstrap script is in scope, make it defer to this AI-native merge flow or
remove it from the recommended path.

## Merge Rules

Good root agent guidance is short, local, and operational:

- what to read first
- how to install and run this repo
- which tests and verification gates matter
- what workflows own planning/execution truth
- which local network, API, hardware, or sandbox constraints matter
- which custom skills to use for recurring work

Deletion is part of the job. Remove or extract content even when it is accurate
if it makes the root files hard to scan and can be represented by a short rule
plus a pointer.

Do not duplicate the same long section in both `AGENTS.md` and `CLAUDE.md`.
Common repo-wide guidance belongs in `AGENTS.md` or `docs/agents/**`; Claude-only
behavior belongs in `CLAUDE.md`.

Use stable operational bridges instead of policy copies. Prefer wording like
"Before broad work, read the active status or steering doc when present; if it
conflicts with the request, ask the user" over repo-specific sections that
duplicate the current milestone, non-goals, review gates, or documentation
taxonomy.

Move reusable procedures into skills instead of expanding root guidance.
Examples: documentation audits, layout refactors, test suite cleanup, phase
pipelines, and bounded refactor gates.

Move repo-specific long procedures into `docs/agents/**` instead of expanding
root guidance. Examples: release process, CI log investigation, GPU setup,
visual validation workflow, PR fix strategy, dependency bootstrap, and
environment-specific caveats.

## Stop Conditions

Stop after a proposal when:

- init output and repo evidence disagree in a way that changes policy
- existing root guidance contains high-risk project-specific constraints
- the user asked for discussion only or report-only
- updating scripts would change how other projects are bootstrapped

Stop after edits when:

- `AGENTS.md` and `CLAUDE.md` are project-local and aligned
- root files are slim enough to scan, or remaining length is justified by
  critical first-read safety rules
- stale symlink-first guidance has been removed or explicitly narrowed to
  shared assets
- copied human-facing project state has been replaced with stable pointers to
  the human docs that own it
- long operational procedures have been extracted to `docs/agents/**`, skills,
  scripts, or human docs as appropriate
- preferred skills are routed by task, not mandated for every turn
- validation/search checks show no obvious stale claims in touched files
