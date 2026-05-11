---
name: doc-keeper
description: Audit and update human-facing authoritative docs when code changes invalidate documented claims. Use proactively after significant code changes, to identify a repo's curated doc set, or to keep AI-agent planning/generated docs from being mistaken for human-review truth.
---

# Doc Keeper

Maintain human-facing documentation by detecting drift between authoritative docs and code, then performing targeted updates.

Prefer a small curated doc set over broad repo-wide doc sweeps. AI-agent-developed repos often contain many generated plans, execution logs, phase artifacts, retrospectives, reports, or implementation notes. Those files may be useful evidence, but they are not automatically human-review authoritative.

## When to Activate

Use this skill when:
- User invokes `/doc-keeper` explicitly
- After completing a significant code change (new subsystem, changed interface, new planning mode, etc.)
- When the user asks about documentation freshness or staleness
- When a phase/milestone completes that may have changed documented behavior

## Modes

### 1. AUDIT mode (default when no args)

Identify the authoritative human-facing doc set, then verify its testable claims against the codebase.

**Steps:**
1. Find the doc orientation surface:
   - Prefer explicit pointers in root `README.md`, `STATUS.md`, `AGENTS.md`, `CLAUDE.md`, or `docs/README.md`
   - Then look for architecture indexes such as `ARCHITECTURE.md`, `docs/architecture/README.md`, or similar
2. Classify docs into:
   - **Human-authoritative**: small files humans are expected to review at HEAD (README, architecture, status/dashboard, contributing, runbooks, durable decision indexes)
   - **Stage-authoritative**: docs authoritative only for a workflow stage (`docs/plans/`, `.planning/STATE.md`, ADRs, active status notes)
   - **Evidence/history**: retrospectives, generated reports, proof bundles, logs, screenshots, benchmark output
   - **Implementation detail**: low-level internals, generated API notes, detailed phase implementation references
3. Select a small audit set:
   - Include files explicitly named as current human-facing sources
   - Include `README.md`, `ARCHITECTURE.md`, and `STATUS.md` when present and linked from orientation docs
   - Include ADR indexes or decision summaries, not every ADR by default
   - Exclude `.planning/**`, `docs/plans/**`, `docs/status/active/**`, `docs/retrospectives/**`, `output/**`, generated reports, and archives unless the user targets them or an authoritative doc links one as current truth
4. Report the selected doc set and skipped buckets before claim results
5. For each **human-authoritative design or runbook doc**:
   a. Read the doc
   b. Extract **testable claims** — statements about interfaces, responsibilities, data flow, extension points, valid/invalid combinations
   c. For each claim, search the codebase to verify it still holds
   d. Classify each claim as: ✅ VERIFIED, ⚠️ DRIFTED, ❓ UNVERIFIABLE
6. Report findings as a table:
   ```
   | Doc | Claims | Verified | Drifted | Unverifiable |
   ```
7. For each DRIFTED claim, show: what the doc says vs what the code shows

**What counts as a testable claim:**
- "The solver returns a GraspPlan" → grep for the return type
- "WBC runs at 50Hz" → check the frequency constant
- "Three DOF layers" → verify the reduction chain exists
- "Invalid: MotionGen + WBC OFF" → check if guard/warning exists
- Extension point lists → verify the interfaces still match

**What is NOT a testable claim:**
- Design rationale ("we chose X because Y")
- Future plans ("this could be extended to...")
- Diagrams (verify manually)

### 2. UPDATE mode (`/doc-keeper update <file>`)

Update a specific doc that has drifted.

**Steps:**
1. Read the target doc
2. Determine whether it is human-authoritative, stage-authoritative, evidence/history, or implementation detail
3. If the target is generated planning/history/evidence, update it only when the user explicitly requested that file; otherwise update the human-facing index or dashboard that points to it
4. Read the README.md documentation standards (if present)
5. Identify which sections have drifted (run mini-audit on this doc)
6. For each drifted section:
   a. Read the relevant code to understand the current state
   b. Rewrite the section to match reality
   c. **Preserve the doc tier** — if it's a design doc, keep it design-level (contracts, not code). If it's an implementation reference, include specifics.
   d. **Preserve extension framing** — current implementations are instances, not absolutes
   e. **Update diagrams** if the data flow or structure changed
7. Show the diff to the user before applying

**Rules for updates:**
- Do NOT downgrade a design doc to implementation detail
- Do NOT remove extension points or "future" slots
- Do NOT add function names or line numbers to design docs
- DO update interface contracts if they changed
- DO update valid/invalid combination rules if new modes were added
- DO add new extension points if new swappable components emerged

### 3. GUARD mode (`/doc-keeper guard`)

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
6. Report: which docs need attention, which sections, severity, and which generated/detail docs were intentionally skipped

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
- Suggested: /doc-keeper update <most-critical-doc>
```

## What This Skill Does NOT Do

- Does not create new docs from scratch (use a doc-architect skill for that)
- Does not sweep every markdown file in the repo
- Does not validate generated planning/history/detail docs by default
- Does not treat implementation references as human-review authoritative just because they exist
- Does not auto-apply changes without showing the user first
- Does not touch code — only reads code, writes docs
