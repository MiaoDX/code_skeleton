---
name: intuitive-layout
description: Audit and aggressively refactor repository folder layout for human-vs-agent surfaces, flat scripts/examples, package organization, test layout, AI navigability, and pre-architecture cleanup. Use whenever the user asks to fix repo or folder layout, organize a flat scripts/ or examples/ directory, separate human docs from AI-agent planning/evidence/history, improve package organization, make a repo easier for agents to navigate, remove stale layout APIs or wrappers, or run architecture cleanup where layout friction may be the first problem.
---

# Intuitive Layout

Make a repository easier to navigate before deeper module refactors. Start by
classifying audiences and path consumers, then propose or apply one bounded
layout slice that makes the new intuitive layout canonical. Once a slice is
approved, migrate callers to the new paths/APIs and remove stale entrypoints by
default.

## Human/Agent Surface Rule

The default human-facing source of truth is intentionally small:

- `README.md`
- `ARCHITECTURE.md`
- `STATUS.md`
- `docs/human/**`

`AGENTS.md` and `CLAUDE.md` are agent-operational docs. Use them for startup
rules, local hazards, command pointers, and skill routing, but do not treat them
as human-authoritative project truth by default.

Agent planning, generated evidence, history, and working notes belong in
explicit agent/process surfaces such as `.planning/**`, `docs/plans/**`,
`docs/retrospectives/**`, `docs/status/active/**`, and `output/**` unless a
human doc intentionally promotes a specific artifact into current truth.

## Bounded Proposal Rule

For broad or ambiguous cleanup, audit first and stop after a decision-complete
proposal. Do not move files, delete tests, rewrite guidance, or edit production
code until the target slice, accepted checklist, evidence level, and stop
condition are explicit.

For a precise target where the user asks for implementation, apply one coherent
vertical slice. Keep newly discovered unrelated ideas parked instead of letting
the work expand by drift.

## Canonical Cleanup Rule

Prefer the new intuitive API, path, module boundary, command shape, or folder
layout over backward compatibility. In an approved cleanup/refactor slice, old
surfaces are migration targets, not contracts.

- Update known in-repo callers, docs, tests, recipes, examples, CI, and command
  references to the new shape.
- Delete old wrappers, aliases, command paths, import paths, dead branches, and
  compatibility shims after known consumers are migrated.
- Keep compatibility only when the user explicitly protects it, a published
  external contract must remain live, or verification shows a non-migratable
  outside-repo consumer.
- If compatibility is kept, mark it temporary and record the removal trigger in
  the active plan, scope gate, or output report.

## Core Principles

- Prefer moderately deep, domain-named folders over large flat buckets.
- Do not deepen by file type alone. Deepen by concept, workflow, module,
  audience, or runtime mode.
- Stop after one useful slice. A layout cleanup should leave the repo easier to
  understand, not half-migrated across many unrelated areas.

## Default Behavior

For broad requests such as "fix our repo layout", "organize scripts", "make
examples easier to navigate", or "separate human and agent docs", use the shared
bounded proposal rule. For an approved or precise layout slice, use the shared
canonical cleanup rule and document migration notes when old commands or imports
intentionally break.

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
   slice with high navigability gain, a clear canonical path, and manageable
   consumer migration work.
6. Stop and ask for approval unless the user already selected that slice.

Every proposal must include:

```text
Target slice: <one bounded area>
Current friction: <what makes the current layout hard to navigate>
Proposed folder shape: <tree sketch or path mapping>
Files likely moved: <representative files or glob patterns>
Path consumers to update: <imports, docs, CI, recipes, scripts, metadata>
Old entrypoints to remove: <wrappers, aliases, commands, imports, or none>
Compatibility kept: <only explicitly protected or externally required paths>
Verification commands: <focused commands and searches>
Main risk: <the breakage or confusion most likely to happen>
```

### 2. LAYOUT

Use this mode only after the user approves a bounded slice or explicitly asks
for a precise move.

Steps:

1. Reconfirm the approved target shape and any external contracts the user
   explicitly wants to keep.
2. Move only the selected files.
3. Update all path consumers found during AUDIT / PROPOSE: imports, docs links,
   CI, `just`/Makefile recipes, scripts, package config, tests, and examples.
4. Remove stale wrappers, aliases, compatibility entrypoints, old command paths,
   and old import paths after known consumers are migrated. Keep compatibility
   only when explicitly protected or externally required, and mark it as
   temporary.
5. Run focused verification:
   - Search for stale paths with `rg`.
   - Run import/collection checks for moved runtime or test files.
   - Run the narrow tests, recipes, link checks, or command smoke tests that
     prove the moved slice works through the new paths.
6. Report moved paths, removed compatibility surfaces, any protected
   compatibility shims, updated consumers, verification, and intentionally
   skipped checks.

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
4. Recommend path fixes, stale compatibility removal, and the path consumers to
   update.

Report findings as:

```text
Verdict: PASS | FLAG | BLOCK
Misplaced files: <paths and target tiers>
Why it matters: <navigation or stability issue>
Suggested fix: <minimal move or doc update>
Stale compatibility: <old path/API to remove or none>
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

Keep layout work centered on navigation, audience boundaries, package
boundaries, command organization, docs surfaces, examples, and test layout.
Layout can reveal architecture friction; redesign module interfaces only when it
is necessary to make the approved move coherent, otherwise park that work for a
deeper architecture/refactor pass.

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
- Prefer the new script layout and API over old command compatibility. Update
  docs, CI, recipes, tests, and known users to the new commands, then delete the
  old script paths.
- Do not hide actively used commands under vague buckets like `misc/` or
  `utils/`.

Examples:

- Deepen flat `examples/` by runnable mode, product workflow, scenario, or
  backend. Update documented commands to the new paths instead of keeping old
  aliases.
- Keep one-command demos discoverable. If a demo becomes support code, move it
  out of `examples/` and update the public entrypoint.

Package internals:

- Deepen package folders by domain concepts already visible in code and docs.
- Avoid moving files just to create one folder per file type.
- When imports are public, prefer migrating in-repo consumers and documenting
  the new canonical imports. Keep adapters or compatibility modules only for
  explicitly protected external contracts.

## Coordination

- Use `intuitive-doc` when the change splits doc audiences, moves human docs,
  changes doc indexes, or risks stale links.
- Use `intuitive-tests` when the test folder layout, markers, fixtures, pruning,
  or behavior quality becomes the main issue.
- Use `improve-codebase-architecture` after layout friction is reduced and the
  next question is module depth, interface design, or code locality.

## Out of Scope

- Keep architecture refactors out of scope unless they are necessary to make the
  approved layout slice coherent.
- Do not reorganize an entire repository in one pass.
- Do not delete planning history, generated evidence, or retrospectives just
  because they are not human-facing.
- Do not leave documented commands, imports, CI paths, or examples pointing at
  old locations after a layout cleanup.
- Do not keep backward-compatibility wrappers by default. Keep them only when
  explicitly protected or externally required, and document the removal trigger.
