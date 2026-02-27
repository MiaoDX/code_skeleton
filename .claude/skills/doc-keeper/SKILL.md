---
name: doc-keeper
description: Audit and update architecture docs when code changes invalidate documented claims. Use proactively after significant code changes, or invoke manually to check doc freshness.
---

# Doc Keeper

Maintain architecture documentation by detecting drift between docs and code, and performing targeted updates.

## When to Activate

Use this skill when:
- User invokes `/doc-keeper` explicitly
- After completing a significant code change (new subsystem, changed interface, new planning mode, etc.)
- When the user asks about documentation freshness or staleness
- When a phase/milestone completes that may have changed documented behavior

## Modes

### 1. AUDIT mode (default when no args)

Scan architecture docs and verify claims against the codebase.

**Steps:**
1. Find the architecture doc index (look for `docs/architecture/README.md` or similar)
2. Read the README to understand the doc structure and tiers
3. For each **design doc** (not implementation references):
   a. Read the doc
   b. Extract **testable claims** — statements about interfaces, responsibilities, data flow, extension points, valid/invalid combinations
   c. For each claim, search the codebase to verify it still holds
   d. Classify each claim as: ✅ VERIFIED, ⚠️ DRIFTED, ❓ UNVERIFIABLE
4. Report findings as a table:
   ```
   | Doc | Claims | Verified | Drifted | Unverifiable |
   ```
5. For each DRIFTED claim, show: what the doc says vs what the code shows

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
2. Read the README.md documentation standards (if present)
3. Identify which sections have drifted (run mini-audit on this doc)
4. For each drifted section:
   a. Read the relevant code to understand the current state
   b. Rewrite the section to match reality
   c. **Preserve the doc tier** — if it's a design doc, keep it design-level (contracts, not code). If it's an implementation reference, include specifics.
   d. **Preserve extension framing** — current implementations are instances, not absolutes
   e. **Update diagrams** if the data flow or structure changed
5. Show the diff to the user before applying

**Rules for updates:**
- Do NOT downgrade a design doc to implementation detail
- Do NOT remove extension points or "future" slots
- Do NOT add function names or line numbers to design docs
- DO update interface contracts if they changed
- DO update valid/invalid combination rules if new modes were added
- DO add new extension points if new swappable components emerged

### 3. GUARD mode (`/doc-keeper guard`)

Check which docs a recent code change might affect.

**Steps:**
1. Run `git diff --name-only HEAD~1` (or user-specified range)
2. Map changed files to documented subsystems:
   - `planner/` changes → check planning_subsystem.md, configuration_space.md
   - `controller.py` changes → check control_and_execution.md
   - `perception/` changes → check perception_pipeline.md
   - `robot_model/` changes → check robot_model_layers.md
   - New config dimensions → check configuration_space.md
   - `*.yml` config changes → check implementation references
3. For each potentially affected doc, run a focused audit on the relevant sections
4. Report: which docs need attention, which sections, severity

## Documentation Standards Awareness

When updating docs, respect the project's documentation standards. Look for these in the architecture README:

- **Two-tier system**: Design docs (durable) vs implementation references (may drift)
- **Design doc rules**: Contracts not code, current = instance, extension points explicit
- **Diagram style**: Mermaid conventions, color coding by subsystem

If no documentation standards are found, apply these defaults:
- Keep design-level docs free of function names, line numbers, and config values
- Frame current implementations as swappable choices
- Include "Adding a New X" sections for extension points

## Output Format

Always end audit/guard output with an actionable summary:

```
## Summary
- N docs checked, M have drift
- Critical: [list docs with broken interface claims]
- Minor: [list docs with stale details]
- Suggested: /doc-keeper update <most-critical-doc>
```

## What This Skill Does NOT Do

- Does not create new docs from scratch (use a doc-architect skill for that)
- Does not validate implementation references (they drift by nature — only flag if contracts changed)
- Does not auto-apply changes without showing the user first
- Does not touch code — only reads code, writes docs
