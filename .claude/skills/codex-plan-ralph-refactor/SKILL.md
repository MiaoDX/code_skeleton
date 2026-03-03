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

#### A. Run Codex Review

Use Bash to run Codex CLI:

```bash
codex exec --skip-git-repo-check \
  -m gpt-5.3-codex \
  --config model_reasoning_effort="high" \
  --sandbox read-only \
  --full-auto \
  -C $(pwd) \
  "Review the GSD phase plans in .planning/phases/{PHASE}-*/ for:
   {FOCUS_PROMPT}.

   Categorize findings as:
   - CRITICAL: Safety bugs, data corruption, architectural blockers
   - MAJOR: API inconsistencies, significant test gaps, coupling issues
   - MINOR: Style, documentation, hygiene

   Report specific file paths and line numbers.
   If no CRITICAL or MAJOR issues found, state 'NO_CRITICAL_MAJOR_ISSUES'."
```

FOCUS_PROMPT mapping:
- `critical`: "Critical safety issues, error handling bugs, architectural blockers"
- `major`: "Major API inconsistencies, test coverage gaps, architectural coupling"
- `all`: "API design consistency, error handling patterns, architecture violations, test coverage gaps"

#### B. Check Early-Stop

Parse Codex output:
- If contains "NO_CRITICAL_MAJOR_ISSUES": Exit loop (early stop)
- Count `[CRITICAL]` and `[MAJOR]` occurrences
- If both counts are 0: Exit loop (early stop)

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

◆ Running Codex review...
✓ Codex review complete

◆ Codex Findings:
- [CRITICAL] Safety bug: known-collision path executes
- [CRITICAL] Stale state: phase mutation uses old variables

Issues found: 2 critical, 0 major, 1 minor

◆ Spawning planner...
✓ Planner updated plans

◆ Verifying plans...
✓ Verification passed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RALPH LOOP — Iteration 2 of 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Running Codex review...
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
