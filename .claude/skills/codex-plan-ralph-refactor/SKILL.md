# codex-plan-ralph-refactor

Review GSD phase plans with Codex and auto-refactor using Ralph Loop with early-stop detection.

## Usage

```
/codex-plan-ralph-refactor <phase-number> [--max-iterations N] [--focus critical|major|all]
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `phase-number` | (required) | Phase to review (e.g., 38) |
| `--max-iterations` | 3 | Maximum Ralph loop iterations |
| `--focus` | all | Issue severity to focus on |

## Examples

```
/codex-plan-ralph-refactor 38                    # Default: 3 iterations, all issues
/codex-plan-ralph-refactor 38 --max-iterations 5  # More iterations
/codex-plan-ralph-refactor 38 --focus critical    # Only critical issues
```

## When to Use

Use this skill when:
- You have existing GSD phase plans that need review
- You want Codex (gpt-5.3-codex, high reasoning) to find issues
- You want automatic plan refactoring via Ralph Loop
- You want early-stop when no critical/major issues remain

---

## Workflow

### 1. Parse Arguments

Extract from user command:
- `PHASE`: Phase number (required)
- `MAX_ITERATIONS`: Default 3, override with `--max-iterations N`
- `FOCUS`: Default "all", choices: critical, major, all

### 2. Validate Phase

Check that:
- `.planning/phases/` exists
- Phase directory `{PHASE}-*` exists
- PLAN.md files exist in phase directory

If not found, error with available phases.

### 3. Ralph Loop (1 to MAX_ITERATIONS)

Initialize loop state:
```python
COVERED_ANGLES = []        # Categories Codex has already explored
PREV_HAD_FIXES = False     # Did previous iteration revise plans?
PREV_ALL_CLEAN = False     # Were all previous findings minor/none?
CODEX_SESSION_ID = None    # Session ID for resume capability
```

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CODEX PLAN RALPH REFACTOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase: {PHASE}
Max Iterations: {MAX_ITERATIONS}
Focus: {FOCUS}
```

For each iteration:

#### A. Run Codex Review (Auto-Choose Resume vs New)

**Session mode auto-selection**:

| Condition | Mode | Rationale |
|-----------|------|-----------|
| Iteration 1 | `exec` (new) | No prior session exists |
| Previous iter revised plans | `resume` | Codex needs context of what changed to verify revisions |
| Previous iter found only MINOR or nothing (stalling) | `exec` (new) | Fresh perspective breaks stuck patterns |
| Every 3rd iteration | Force `exec` (new) | Diversity injection |

Display the choice:
```
◆ Session mode: {resume|new} — {reason}
```

**Build the review prompt** with angle expansion (after iteration 1):

```
Review the GSD phase plans in .planning/phases/{PHASE}-*/ for:
{FOCUS_PROMPT}.

Categorize findings as:
- CRITICAL: Safety bugs, data corruption, architectural blockers
- MAJOR: API inconsistencies, significant test gaps, coupling issues
- MINOR: Style, documentation, hygiene

Report specific file paths and line numbers.
If no CRITICAL or MAJOR issues found, state 'NO_CRITICAL_MAJOR_ISSUES'.

{ANGLE_EXPANSION_BLOCK if COVERED_ANGLES is non-empty}
```

The `ANGLE_EXPANSION_BLOCK` (only included after iteration 1):

```
## Expand Your Review Angles

Prior iterations already covered these categories:
{for each angle in COVERED_ANGLES}
- {angle}
{end for}

You MUST explore NEW angles not yet covered. Consider:
- Concurrency & race conditions in the planned approach
- Error recovery & rollback strategies
- Edge cases not addressed in the plan
- Missing integration points between components
- Scalability assumptions
- Security implications of the design
- Dependency risks & version constraints
- Observability & debugging gaps in the architecture
- Backward compatibility concerns

Focus on angles NOT in the "already covered" list above.
If you have genuinely exhausted all angles, state 'NO_CRITICAL_MAJOR_ISSUES'.
```

**If using `exec` (new session)**:

```bash
codex exec --skip-git-repo-check \
  -m gpt-5.3-codex \
  --config model_reasoning_effort="high" \
  --sandbox read-only \
  --full-auto \
  -C $(pwd) \
  "<REVIEW_PROMPT>"
```

Save the session ID from output as `CODEX_SESSION_ID` for potential future resume.

**If using `resume` (continuing prior session)**:

```bash
codex resume {CODEX_SESSION_ID} --skip-git-repo-check \
  -m gpt-5.3-codex \
  --config model_reasoning_effort="high" \
  --sandbox read-only \
  --full-auto \
  -C $(pwd) \
  "<REVIEW_PROMPT>"
```

If `resume` fails (session expired, etc.), fall back to `exec` automatically.

FOCUS_PROMPT mapping:
- `critical`: "Critical safety issues, error handling bugs, architectural blockers"
- `major`: "Major API inconsistencies, test coverage gaps, architectural coupling"
- `all`: "API design consistency, error handling patterns, architecture violations, test coverage gaps"

#### B. Check Early-Stop & Track Angles

Parse Codex output:
- If contains "NO_CRITICAL_MAJOR_ISSUES": Exit loop (early stop)
- Count `[CRITICAL]` and `[MAJOR]` occurrences
- If both counts are 0: Exit loop (early stop)

**Track covered angles**: Extract categories Codex explored (e.g., "Architecture: coupling between X and Y", "Error handling: missing rollback") and add to `COVERED_ANGLES`.

Update session state for next iteration's auto-choice:
```python
PREV_HAD_FIXES = True  # if planner revised plans
PREV_ALL_CLEAN = (critical_count == 0 and major_count == 0)
```

Display findings:
```
◆ Codex Findings:
- [CRITICAL] ...
- [MAJOR] ...

Issues found: X critical, Y major, Z minor
```

#### C. Spawn Planner (if issues remain)

Use Task tool to spawn planner subagent:

```python
Task(
    prompt="Revise Phase {PHASE} plans to address Codex findings:\n\n{CODEX_OUTPUT}",
    subagent_type="general-purpose",
    description=f"Revise Phase {PHASE} plans"
)
```

The planner should:
1. Read all existing PLAN.md files
2. Update plans to address findings (CRITICAL first, then MAJOR)
3. Make minimal targeted changes
4. Return "## PLANNING COMPLETE"

#### D. Spawn Plan-Checker

Use Task tool to spawn checker:

```python
Task(
    prompt="Verify Phase {PHASE} plans address the requirements",
    subagent_type="gsd-plan-checker",
    description=f"Verify Phase {PHASE} plans"
)
```

Checker should return:
- "## VERIFICATION PASSED" or
- "## ISSUES FOUND" with structured list

### 4. Final Summary

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RALPH LOOP COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Iterations completed: N
Early stopped: Yes/No
```

If early stopped:
```
✓ All critical and major issues resolved

Next: /gsd:execute-phase {PHASE}
```

If max iterations reached:
```
⚠ Max iterations reached. Some issues may remain.

Consider:
- Manual plan review
- Running with --max-iterations 5
- Running with --focus critical
```

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Phase not found | Error with available phases |
| No PLAN.md files | Suggest /gsd:plan-phase first |
| Codex CLI not found | Error, suggest pip install openai-codex |
| Codex timeout | Report, suggest retry or manual |
| Planner fails | Offer retry, skip, or abort |

---

## Example Session

```
User: /codex-plan-ralph-refactor 38

Claude:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CODEX PLAN RALPH REFACTOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase: 38
Max Iterations: 3
Focus: all

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RALPH LOOP — Iteration 1 of 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Session mode: new — first iteration
◆ Running Codex review...
✓ Codex review complete

◆ Codex Findings:
- [CRITICAL] Safety bug: known-collision path executes
- [CRITICAL] Stale state: phase mutation uses old variables

Issues found: 2 critical, 0 major, 1 minor
Angles covered: Safety (collision), Correctness (stale state)

◆ Spawning planner...
✓ Planner updated plans

◆ Verifying plans...
✓ Verification passed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RALPH LOOP — Iteration 2 of 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Session mode: resume — verifying plan revisions from iteration 1
◆ Running Codex review (exploring new angles)...
✓ Codex review complete

✓ Early stop: No critical or major issues found

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RALPH LOOP COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Iterations completed: 2
Early stopped: Yes

✓ All critical and major issues resolved

Next: /gsd:execute-phase 38
```
