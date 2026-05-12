---
name: intuitive-layout
description: Audit and refactor repository folder layout for human-vs-agent surfaces, flat scripts/examples, package organization, test layout, AI navigability, and pre-architecture cleanup. Use whenever the user asks to fix repo or folder layout, organize a flat scripts/ or examples/ directory, separate human docs from AI-agent planning/evidence/history, improve package organization, make a repo easier for agents to navigate, or run architecture cleanup where layout friction may be the first problem.
---

# Intuitive Layout

Make a repository easier to navigate before deeper module refactors. Start by
classifying audiences and path consumers, then propose or apply one bounded
layout slice that preserves runnable entrypoints.

## Core Principles

- Keep the human-only orientation small: `README.md`, `ARCHITECTURE.md`,
  `STATUS.md`, and `docs/human/**`.
- Keep AI-agent planning, evidence, history, and working notes in explicit
  agent/process folders such as `.planning/**`, `docs/plans/**`,
  `docs/retrospectives/**`, `docs/status/active/**`, and `output/**`.
- Prefer moderately deep, domain-named folders over large flat buckets.
- Do not deepen by file type alone. Deepen by concept, workflow, module,
  audience, or runtime mode.
- Preserve runnable entrypoints, import paths, public command paths, and
  documented examples before moving files.
- Stop after one useful slice. A layout cleanup should leave the repo easier to
  understand, not half-migrated across many unrelated areas.

## Default Behavior

For broad requests such as "fix our repo layout", "organize scripts", "make
examples easier to navigate", or "separate human and agent docs", run
**AUDIT / PROPOSE** first and stop after a decision-complete proposal.

Do not move files until the user has explicitly selected a target slice, unless
the prompt already names a precise slice and asks for implementation.

## Modes

### 1. AUDIT / PROPOSE

Use this mode by default.

Steps:

1. Inventory the top-level tree with `rg --files`, `find`, or the repo's own
   index. Identify root orientation files, packages, tests, scripts, examples,
   docs, generated output, and planning/workflow folders.
2. Classify each visible area by primary audience:
   - **Human orientation**: concise project, architecture, status, setup, and
     runbook surfaces.
   - **Runtime code**: importable packages, binaries, application entrypoints,
     config, migrations, and assets used at runtime.
   - **Tests**: unit, contract, integration, regression, fixtures, and support
     helpers.
   - **Examples / demos**: runnable samples, scenario scripts, notebooks, or
     product workflows.
   - **Scripts / tools**: maintainer workflows, codegen, checks, local demos,
     data transforms, and release helpers.
   - **AI-agent workspace**: planning, execution notes, generated reports,
     retrospectives, active status notes, and evidence.
3. Identify flat buckets that now mix concepts, audiences, or stability levels.
   Common signals: a large `scripts/` directory, many unrelated `examples/`,
   docs that mix human orientation with agent traces, or packages where one
   directory contains several domain concepts.
4. Find path consumers before proposing moves: imports, docs links, CI
   workflows, `just`/Makefile recipes, package metadata, pre-commit hooks,
   deployment config, shell scripts, dashboards, and user-facing commands.
5. Recommend one primary layout slice and, when useful, one fallback. Favor the
   slice with high navigability gain and low entrypoint risk.
6. Stop and ask for approval unless the user already selected that slice.

Every proposal must include:

```text
Target slice: <one bounded area>
Current friction: <what makes the current layout hard to navigate>
Proposed folder shape: <tree sketch or path mapping>
Files likely moved: <representative files or glob patterns>
Path consumers to update: <imports, docs, CI, recipes, scripts, metadata>
Verification commands: <focused commands and searches>
Main risk: <the breakage or confusion most likely to happen>
```

### 2. LAYOUT

Use this mode only after the user approves a bounded slice or explicitly asks
for a precise move.

Steps:

1. Reconfirm the approved target shape and the public paths that must keep
   working.
2. Move only the selected files.
3. Update all path consumers found during AUDIT / PROPOSE: imports, docs links,
   CI, `just`/Makefile recipes, scripts, package config, tests, and examples.
4. Keep stable wrappers or compatibility entrypoints when documented commands
   or public paths would otherwise break.
5. Run focused verification:
   - Search for stale paths with `rg`.
   - Run import/collection checks for moved runtime or test files.
   - Run the narrow tests, recipes, link checks, or command smoke tests that
     prove the moved slice still works.
6. Report moved paths, compatibility shims, updated consumers, verification,
   and any intentionally skipped checks.

### 3. GUARD

Use this mode to inspect a diff or proposed file additions and report whether
new files landed in the wrong layout tier.

Steps:

1. Read the changed-file list from the user, `git diff --name-only`, or the
   specified range.
2. Classify each new or moved file by audience and stability level.
3. Flag files that appear to be in the wrong tier, such as generated evidence
   in human docs, human orientation buried in planning folders, examples that
   should be tests, or one-off local scripts added as public commands.
4. Recommend minimal path fixes and the path consumers to update.

Report findings as:

```text
Verdict: PASS | FLAG | BLOCK
Misplaced files: <paths and target tiers>
Why it matters: <navigation or stability issue>
Suggested fix: <minimal move or doc update>
Verification: <searches or commands>
```

### 4. ARCHITECTURE BRIDGE

Use this mode before `improve-codebase-architecture` when the user asks for
architecture cleanup but the first friction is finding things, not designing
deeper modules.

Steps:

1. Run AUDIT / PROPOSE on the layout areas that block understanding.
2. Recommend a layout-first slice if simple moves would reduce navigation cost.
3. If the folder layout is already clear enough, say so and hand off to
   `improve-codebase-architecture` for module/interface depth.

Do not propose new module interfaces in this skill. Layout can reveal
architecture friction, but deeper module design belongs to
`improve-codebase-architecture`.

## Target Patterns

Use these as defaults, then adapt to the repo's existing conventions.

Human docs:

```text
README.md
ARCHITECTURE.md
STATUS.md
docs/human/
```

Agent and process surfaces:

```text
docs/agents/
docs/plans/
docs/retrospectives/
docs/status/active/
.planning/
output/
```

Tests, when layout is in scope:

```text
tests/
  unit/
  contract/
  integration/
  regression/
  support/
```

Defer detailed test taxonomy, marker strategy, pruning, fixture extraction, and
test behavior quality to `intuitive-tests`.

Scripts:

- Deepen a flat `scripts/` directory by workflow or domain once enough files
  share a purpose, such as `scripts/reports/`, `scripts/dev/`,
  `scripts/release/`, `scripts/data/`, or `scripts/smoke/`.
- Keep stable wrappers at old public command paths when docs, CI, recipes, or
  users call them directly.
- Do not hide actively used commands under vague buckets like `misc/` or
  `utils/`.

Examples:

- Deepen flat `examples/` by runnable mode, product workflow, scenario, or
  backend. Preserve documented commands.
- Keep one-command demos discoverable. If a demo becomes support code, move it
  out of `examples/` and update the public entrypoint.

Package internals:

- Deepen package folders by domain concepts already visible in code and docs.
- Avoid moving files just to create one folder per file type.
- When imports are public, prefer adapters, compatibility modules, or explicit
  migration notes over silent path breakage.

## Coordination

- Use `intuitive-doc` when the change splits doc audiences, moves human docs,
  changes doc indexes, or risks stale links.
- Use `intuitive-tests` when the test folder layout, markers, fixtures, pruning,
  or behavior quality becomes the main issue.
- Use `improve-codebase-architecture` after layout friction is reduced and the
  next question is module depth, interface design, or code locality.

## Out of Scope

- Do not perform architecture refactors in this skill.
- Do not reorganize an entire repository in one pass.
- Do not delete planning history, generated evidence, or retrospectives just
  because they are not human-facing.
- Do not break documented commands, imports, or CI paths without wrappers or a
  deliberate migration plan.
