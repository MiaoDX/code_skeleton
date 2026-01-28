---
description: Show the last N phases status for GSD
---

Display a summary of recent GSD phase statuses and quick tasks.

**Usage:** `gsd_status [N]`

- `N`: Number of recent phases/tasks to show (default: 5)

## Output Format

```
GSD Status - Last 5 phases/tasks

Phases:
  Phase 1: Project Setup          [COMPLETED]  2026-01-20
  Phase 2: Core Implementation    [IN_PROGRESS] 2026-01-22
  Phase 3: Testing                [PENDING]

Quick Tasks:
  #001: Fix typo in README        [COMPLETED]  2026-01-21  (abc1234)
  #002: Update dependencies       [COMPLETED]  2026-01-22  (def5678)

Current: Phase 2 (IN_PROGRESS)
Next:    Phase 3 (PENDING)
```

## Implementation

**1. Check for GSD project**
- Verify `.planning/STATE.md` exists
- If not found: "No active GSD project found. Run /gsd:new-project first."

**2. Parse STATE.md**
- Extract current phase from "Current phase" line
- Extract "Quick Tasks Completed" table rows
- Parse phase statuses from the document

**3. Parse ROADMAP.md (if exists)**
- Read phase list and their statuses
- Match with current state from STATE.md

**4. Display summary**
- Show last N phases (or all if fewer than N)
- Show last N quick tasks (or all if fewer than N)
- Highlight current phase
- Show next pending phase

**5. Optional flags**
- `--all` or `-a`: Show all phases/tasks
- `--phases-only`: Show only phases
- `--quick-only`: Show only quick tasks
