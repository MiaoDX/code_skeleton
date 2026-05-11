---
name: intuitive-doc
description: Create and maintain an intuitive human documentation surface for AI-agent-developed repos. Use when humans should only need README.md, ARCHITECTURE.md, STATUS.md, and docs/human/** while planning logs, generated docs, retrospectives, ADR detail, and implementation evidence stay in AI-agent-only folders.
---

# Intuitive Doc

Maintain a small human-facing documentation surface and keep it aligned with code.

Default human surface:
- `README.md`
- `ARCHITECTURE.md`
- `STATUS.md`
- `docs/human/**`

AI-agent-developed repos often contain many plans, execution logs, ADRs,
retrospectives, proof reports, and implementation notes. Keep those useful, but
do not make human developers read them for normal review.

## Perspective Levels

Use the right level of abstraction before checking details:

- **L0 Orientation**: `README.md`, `STATUS.md`, and doc indexes. These must tell
  a human what the repo does now, what can be run now, and where the current
  source of truth lives.
- **L1 Architecture / domain map**: `ARCHITECTURE.md`, technical design docs,
  and domain vocabulary. These must name the major subsystems, contracts,
  data flows, extension points, and proof boundaries that exist in the current
  codebase.
- **L2 Runbooks / operator docs**: setup, local development, deployment, model
  matrices, and command guides. These must match real commands, env vars,
  artifacts, ports, and supported combinations.
- **L3 Evidence / implementation detail**: plans, retrospectives, generated
  reports, fixtures, and logs. These are evidence unless explicitly promoted
  into the human surface.

For L0/L1 docs, do a zoom-out pass before claim-by-claim checking: map the
top-level packages, examples, scripts, just recipes, and active status into the
project's domain language. If an available `zoom-out` skill exists, use it when
the repo has grown a new major subsystem, the user asks for higher-level
perspective, or the architecture/design docs feel locally correct but globally
incomplete.

## When to Activate

Use this skill when:
- User invokes `intuitive-doc`, `/intuitive-doc`, or `$intuitive-doc` explicitly
- The repo's human doc surface needs to be created, simplified, or reorganized
- After completing a significant code change (new subsystem, changed interface, new planning mode, etc.)
- When the user asks about documentation freshness or staleness
- When a phase/milestone completes that may have changed documented behavior

## Modes

### 1. AUDIT mode (default when no args)

Identify the human-facing doc surface, then verify its testable claims against the codebase.

**Steps:**
1. Find the doc orientation surface:
   - Prefer explicit pointers in root `README.md`, `STATUS.md`, `AGENTS.md`, `CLAUDE.md`, or `docs/README.md`
   - Then look for architecture indexes such as `ARCHITECTURE.md`, `docs/architecture/README.md`, or similar
2. Classify docs into:
   - **Human-authoritative**: root `README.md`, `ARCHITECTURE.md`, `STATUS.md`, and docs under `docs/human/**`
   - **Stage-authoritative**: docs authoritative only for a workflow stage (`docs/plans/`, `.planning/STATE.md`, ADRs, active status notes)
   - **Evidence/history**: retrospectives, generated reports, proof bundles, logs, screenshots, benchmark output
   - **Implementation detail**: low-level internals, generated API notes, detailed phase implementation references
3. Select a small audit set:
   - Include files explicitly named as current human-facing sources
   - Include `README.md`, `ARCHITECTURE.md`, and `STATUS.md` when present and linked from orientation docs
   - Include `docs/human/**` when present
   - Use ADR indexes, `.planning/**`, and `docs/plans/**` as evidence only unless the user explicitly targets them
   - Exclude `.planning/**`, `docs/plans/**`, `docs/status/active/**`, `docs/retrospectives/**`, `output/**`, generated reports, and archives unless the user targets them or an authoritative doc links one as current truth
4. Build a codebase freshness map before detailed claims:
   - Top-level packages and their roles
   - Example/demo entrypoints
   - Script and `just` recipe surfaces
   - Public protocols/contracts, schemas, reports, and artifact outputs
   - Active focus from `STATUS.md` and, as evidence only, `.planning/STATE.md`
   - Any major subsystem present in code but missing or underweighted in L0/L1 docs
5. Report the selected doc set and skipped buckets before claim results
6. For each **human-authoritative design or runbook doc**:
   a. Read the doc
   b. Extract **testable claims** — statements about interfaces, responsibilities, data flow, extension points, valid/invalid combinations
   c. For L0/L1 docs, also extract **coverage claims by omission**: what major subsystems or run modes the doc implies are the whole project
   d. For each claim, search the codebase to verify it still holds
   e. For each coverage-by-omission claim, check whether the freshness map shows a missing major subsystem, public contract, or runnable mode
   f. Classify each claim as: ✅ VERIFIED, ⚠️ DRIFTED, ❓ UNVERIFIABLE
7. Report findings as a table:
   ```
   | Doc | Claims | Verified | Drifted | Unverifiable |
   ```
8. For each DRIFTED claim, show: what the doc says or omits vs what the code shows

**What counts as a testable claim:**
- "The solver returns a GraspPlan" → grep for the return type
- "WBC runs at 50Hz" → check the frequency constant
- "Three DOF layers" → verify the reduction chain exists
- "Invalid: MotionGen + WBC OFF" → check if guard/warning exists
- Extension point lists → verify the interfaces still match
- "README lists what you can run" → verify examples, scripts, and `just` recipes exist
- "ARCHITECTURE describes the operating modes" → verify top-level modules and current entrypoints are represented, including newer major subsystems
- "Design doc names the platform strategy" → verify the current codebase has not added another platform, contract, or proof path that changes the project map

**What is NOT a testable claim:**
- Design rationale ("we chose X because Y")
- Future plans ("this could be extended to...")
- Diagrams (verify manually)

### 2. UPDATE mode (`/intuitive-doc update <file>`)

Update a specific doc that has drifted.

**Steps:**
1. Read the target doc
2. Determine whether it is human-authoritative, stage-authoritative, evidence/history, or implementation detail
3. If the target is generated planning/history/evidence, update it only when the user explicitly requested that file; otherwise update the human-facing doc that points to it
4. Read the README.md documentation standards (if present)
5. Identify which sections have drifted (run mini-audit on this doc)
6. Select the perspective level for the target:
   - L0/L1 docs require a zoom-out freshness check against top-level code, examples, scripts, recipes, and active status before rewriting.
   - L2 docs require concrete command/env/artifact validation.
   - L3 docs should usually remain evidence/history unless explicitly targeted.
7. For each drifted section:
   a. Read the relevant code to understand the current state
   b. Rewrite the section to match reality
   c. **Preserve the doc tier** — if it's a design doc, keep it design-level (contracts, not code). If it's an implementation reference, include specifics.
   d. **Preserve extension framing** — current implementations are instances, not absolutes
   e. **Update diagrams** if the data flow or structure changed
8. If the user has not already asked you to implement the update, show the diff before applying. If they explicitly approved the cleanup, apply the scoped doc changes and summarize the diff afterward.

**Rules for updates:**
- Do NOT downgrade a design doc to implementation detail
- Do NOT remove extension points or "future" slots
- Do NOT add function names or line numbers to design docs
- DO update interface contracts if they changed
- DO update valid/invalid combination rules if new modes were added
- DO add new extension points if new swappable components emerged
- DO update README, architecture, and technical design when the codebase gains a major subsystem, public contract, runnable mode, or proof boundary, even if the old wording is not strictly false
- DO keep high-level docs human-oriented: name subsystems and contracts, not every helper function

### 3. GUARD mode (`/intuitive-doc guard`)

Check which human-facing docs a recent code change might affect.

**Steps:**
1. Run `git diff --name-only HEAD~1` (or user-specified range)
2. Identify the curated doc set using AUDIT mode's selection rules
3. Map changed files to documented subsystems:
   - `planner/` changes → check planning_subsystem.md, configuration_space.md
   - `controller.py` changes → check control_and_execution.md
   - `perception/` changes → check perception_pipeline.md
   - `robot_model/` changes → check robot_model_layers.md
   - New config dimensions → check configuration_space.md
   - `*.yml` config changes → check implementation references
4. Prefer human-facing indexes, architecture docs, dashboards, and runbooks over generated phase/planning docs
5. For each potentially affected doc, run a focused audit on the relevant sections
6. For L0/L1 docs, check whether the diff introduces or removes a major subsystem, command surface, public contract, or report artifact that should change the zoomed-out repo map
7. Report: which docs need attention, which sections, severity, and which generated/detail docs were intentionally skipped

## Documentation Standards Awareness

When updating docs, respect the project's documentation standards. Look for these in the orientation and architecture surfaces:

- **Curated set**: A small set of docs humans review at HEAD
- **Two-tier system**: Design docs (durable) vs implementation references (may drift)
- **Design doc rules**: Contracts not code, current = instance, extension points explicit
- **Diagram style**: Mermaid conventions, color coding by subsystem

If no documentation standards are found, apply these defaults:
- Keep design-level docs free of function names, line numbers, and config values
- Frame current implementations as swappable choices
- Include "Adding a New X" sections for extension points
- Treat generated planning, status scratchpads, retrospectives, reports, and archives as evidence/history unless explicitly promoted by an index

## Output Format

Always end audit/guard output with an actionable summary:

```
## Summary
- Authoritative set: [list docs audited]
- Skipped as generated/detail/history: [list buckets]
- N docs checked, M have drift
- Critical: [list docs with broken interface claims]
- Minor: [list docs with stale details]
- Suggested: /intuitive-doc update <most-critical-doc>
```

## What This Skill Does NOT Do

- Does not create broad new doc suites from scratch; it may create a small `docs/human/README.md` index or move existing docs into the human surface
- Does not sweep every markdown file in the repo
- Does not validate generated planning/history/detail docs by default
- Does not treat implementation references as human-review authoritative just because they exist
- Does not auto-apply broad documentation sweeps without explicit user approval
- Does not touch code — only reads code, writes docs
