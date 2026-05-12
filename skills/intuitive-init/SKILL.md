---
name: intuitive-init
description: Initialize, audit, merge, and refresh project-local AGENTS.md and CLAUDE.md files from existing repo guidance, agent /init suggestions, and intuitive workflow defaults. Use when setting up a repo for Claude Code/Codex, replacing symlinked agent files with local guidance, rerunning agent init after weeks of drift, or aligning a repo to intuitive-doc, intuitive-layout, intuitive-tests, intuitive-build, and intuitive-refactor without overwriting project-specific hints.
---

# Intuitive Init

Set up repo-local AI agent guidance without turning shared defaults into a
symlinked source of truth. Shared skills should travel across projects;
`AGENTS.md` and `CLAUDE.md` should preserve the local repo's commands,
constraints, workflow choices, and hard-won mistakes.

## Core Rule

Treat generated init output and Intuitive Flow defaults as reviewers, not
authority.

Authoritative inputs, in order:

1. System/developer/user instructions for the current session.
2. Existing project-local `AGENTS.md` and `CLAUDE.md`.
3. Root orientation docs such as `README.md`, `ARCHITECTURE.md`, `STATUS.md`,
   `docs/agents/**`, and command docs.
4. Actual repo commands, scripts, package metadata, CI config, and tests.
5. Agent `/init` suggestions.
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
   - If the current interface cannot run `/init`, say so and continue from the
     repo evidence.
4. Classify current guidance:
   - **Preserve**: project commands, env setup, permissions, local hazards,
     workflow source-of-truth rules, domain vocabulary, test gates.
   - **Merge**: concise shared behavior that still fits this repo.
   - **Replace**: stale setup steps, symlink-first instructions for root agent
     files, generic advice duplicated by system behavior.
   - **Remove**: obsolete commands, absolute paths from another project,
     process notes that belong in skills instead of root guidance.
5. Add or refresh a short preferred-skills block when relevant:
   - `$intuitive-init` for agent guidance initialization and periodic refresh.
   - `$intuitive-doc` for human-facing docs and doc drift.
   - `$intuitive-layout` for repo/folder organization.
   - `$intuitive-tests` for test-suite structure and behavior-focused cleanup.
   - `$intuitive-build` for fuzzy idea to planned execution.
   - `$intuitive-refactor` before broad architecture or refactor work.
   - `$intuitive-squash` for cleaning local agent commit history before handoff.
6. Produce a merged proposal first:
   - Summarize the source inputs used.
   - Explain what was preserved, replaced, and removed.
   - Show the diff or proposed file contents.
7. Apply changes only when the user has asked for direct implementation or
   approves the proposal. When applying, update both `AGENTS.md` and
   `CLAUDE.md` if both exist and the rule applies to both agents.

## Modes

### Audit

Use when the user asks what should change, or when broad edits would be risky.

Report:

```text
Agent files:
Init discovery:
Project-specific guidance to preserve:
Shared boilerplate to remove:
Missing preferred-skill routing:
Suggested edits:
Apply now? <yes/no needed unless already authorized>
```

### Apply

Use when the user explicitly asks to update the repo guidance.

Steps:

1. Run the default workflow.
2. Edit only `AGENTS.md`, `CLAUDE.md`, and directly related init docs/scripts
   the user named.
3. Keep the files self-contained. Do not replace critical rules with "see
   another file" unless the repo already requires that pattern.
4. Preserve differences between Claude and Codex when they matter.
5. Search for stale setup/init claims after editing.

### Refresh

Use after several weeks, major command changes, a new subsystem, repeated agent
mistakes, or a changed planning workflow.

Run the same workflow as Apply, but be stricter about removing stale commands
and softer about adding new process. A refresh should reduce drift, not expand
root guidance into a manual.

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

Move reusable procedures into skills instead of expanding root guidance.
Examples: documentation audits, layout refactors, test suite cleanup, phase
pipelines, and bounded refactor gates.

## Stop Conditions

Stop after a proposal when:

- init output and repo evidence disagree in a way that changes policy
- existing root guidance contains high-risk project-specific constraints
- the user asked for discussion only or report-only
- updating scripts would change how other projects are bootstrapped

Stop after edits when:

- `AGENTS.md` and `CLAUDE.md` are project-local and aligned
- stale symlink-first guidance has been removed or explicitly narrowed to
  shared assets
- preferred skills are routed by task, not mandated for every turn
- validation/search checks show no obvious stale claims in touched files
