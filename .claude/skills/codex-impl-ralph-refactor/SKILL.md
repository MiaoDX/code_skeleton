# codex-impl-ralph-refactor

Review implemented code with Codex and iterative Ralph Loop — Claude triages findings, fixes real issues, and feeds dismissed false positives back as hints so Codex stops repeating them.

## Usage

```
/codex-impl-ralph-refactor <phase-number|git-ref> [--max-iterations N] [--fix-level must|improve|all] [--scope path/]
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `phase-number` or `git-ref` | (required) | GSD phase number (e.g., 38) or git ref (e.g., `main`, `abc1234`) |
| `--max-iterations` | 3 | Maximum review-triage-fix loop iterations |
| `--fix-level` | improve | What to auto-fix: `must` (MUST-FIX only), `improve` (MUST-FIX + IMPROVE), `all` (everything including NITPICK) |
| `--scope` | (none) | Optional path filter to restrict review (e.g., `src/auth/`) |

## Examples

```
/codex-impl-ralph-refactor 42                              # Review phase 42 implementation
/codex-impl-ralph-refactor 42 --max-iterations 5            # More iterations for thorough review
/codex-impl-ralph-refactor main --scope src/core/            # Review changes since main, scoped to src/core/
/codex-impl-ralph-refactor abc1234 --fix-level must          # Only auto-fix security/correctness bugs
/codex-impl-ralph-refactor 38 --fix-level all                # Auto-fix everything including nitpicks
```

## When to Use

Use this skill when:
- A GSD phase has been executed and you want to review the **implemented code** (not plans)
- You want Codex (gpt-5.3-codex, high reasoning) to find bugs in code changes
- You want Claude to triage findings (dismiss false positives, assign severity)
- You want automatic fixing of real issues with iterative convergence
- You want a feedback loop that prevents Codex from repeating dismissed suggestions

Do NOT use this for reviewing plans — use `/codex-plan-ralph-refactor` for that.

---

## Severity Levels (Assigned by Claude, NOT Codex)

Claude triages every Codex finding into one of four levels:

| Level | Meaning | Auto-Fix? | Action |
|-------|---------|-----------|--------|
| **MUST-FIX** | Security bugs, correctness errors, data corruption, crashes | Always | Fix immediately |
| **IMPROVE** | Genuine quality gains — edge cases, error handling, API misuse, logic clarity | Default yes | Fix — if it genuinely makes code better |
| **NITPICK** | Purely subjective style preferences, cosmetic-only changes | Only with `--fix-level all` | Report for user to decide |
| **DISMISSED** | False positive, misleading, or inapplicable suggestion | Never | Add to hint context for next loop |

**Triage bar**: IMPROVE means "does this genuinely make the codebase better?" If yes, fix it. If it's just taste, it's a NITPICK.

---

## Workflow

### 1. Parse Arguments

Extract from user command:
- `TARGET`: Phase number or git ref (required)
- `MAX_ITERATIONS`: Default 3, override with `--max-iterations N`
- `FIX_LEVEL`: Default "improve", choices: must, improve, all
- `SCOPE`: Optional path filter

Determine target type:
- If numeric: treat as GSD phase number
- Otherwise: treat as git ref

### 2. Collect Code Changes

#### For GSD Phase

```bash
# Find phase directory
ls .planning/phases/{TARGET}-*/

# Get commit range for this phase
git log --oneline --all --grep="Phase {TARGET}" | head -20
# Or find commits from phase execution timestamps
git log --oneline --since="phase start" --until="phase end"
```

Identify the commit range that covers this phase's implementation. Use `git diff <first_commit>^...<last_commit>` to get the full diff.

#### For Git Ref

```bash
git diff {TARGET}...HEAD
```

#### Scope Filter

If `--scope` is set, add `-- {SCOPE}` to all git diff commands.

#### Extract Changed Files

```bash
git diff --name-only {RANGE} [-- {SCOPE}]
```

Store:
- `DIFF_CONTENT`: Full diff output
- `CHANGED_FILES`: List of changed file paths
- `COMMIT_RANGE`: The git range string for reference

If no changes found, report and exit.

### 3. Initialize Loop State

```python
DISMISSED_HINTS = []       # Accumulates across iterations
ITERATION = 0
ALL_FIXES = []             # Track all fixes applied
ALL_NITPICKS = []          # Track nitpicks for final report
ALL_DISMISSED = []         # Track dismissed items for transparency
```

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CODEX IMPL RALPH REFACTOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Target: {TARGET} ({type: phase|git-ref})
Changed files: {N}
Max Iterations: {MAX_ITERATIONS}
Fix Level: {FIX_LEVEL}
Scope: {SCOPE or "all"}
```

### 4. Review Loop (1 to MAX_ITERATIONS)

For each iteration:

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 REVIEW LOOP — Iteration {ITERATION} of {MAX_ITERATIONS}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### A. Build Codex Review Prompt

Construct the review prompt with hint injection:

```
Review the following code changes for issues.

## Changed Files
{CHANGED_FILES list}

## Instructions
- Review the implementation changes in the listed files
- Categorize findings by: Security, Correctness, Performance, Maintainability
- For each finding: cite exact file:line, describe the issue, explain why it matters
- If no significant issues are found, state "NO_SIGNIFICANT_ISSUES"

{HINT_BLOCK if DISMISSED_HINTS is non-empty}
```

The `HINT_BLOCK` (only included when `DISMISSED_HINTS` is non-empty):

```
## IMPORTANT: Previously Dismissed Findings

The following suggestions from prior review iterations have been analyzed
and determined to be incorrect or inapplicable. Do NOT repeat them.
If you still believe any are valid, provide NEW evidence or reasoning
that was not considered before:

{for each hint in DISMISSED_HINTS}
- [DISMISSED] "{hint.suggestion}" — Reason: {hint.reason}
{end for}
```

#### B. Run Codex Review

Use Bash to run Codex CLI:

```bash
codex exec --skip-git-repo-check \
  -m gpt-5.3-codex \
  --config model_reasoning_effort="high" \
  --sandbox read-only \
  --full-auto \
  -C $(pwd) \
  "<REVIEW_PROMPT>"
```

Capture the full Codex output as `CODEX_OUTPUT`.

If Codex CLI fails or times out, report the error and offer to retry or skip.

#### C. Check Codex Early-Stop

Parse `CODEX_OUTPUT`:
- If contains `NO_SIGNIFICANT_ISSUES`: proceed to early-stop (but still go through triage to confirm)

#### D. Claude Triage

This is done inline (NOT in a subagent) — Claude analyzes directly:

1. **Read referenced files**: For each file:line cited by Codex, read the actual code
2. **Evaluate each finding**: For every Codex suggestion:
   - Is the code actually doing what Codex claims? (Check the real code, not just the diff)
   - Is this a real bug, a genuine improvement, a style preference, or a false positive?
   - Does the project's existing patterns/conventions make this suggestion inapplicable?
3. **Assign severity**: MUST-FIX / IMPROVE / NITPICK / DISMISSED
4. **For DISMISSED**: Record the suggestion text and the reason for dismissal

Display triage results as a structured table:

```
◆ Triage Results (Iteration {ITERATION}):

| # | Severity | File:Line | Finding | Rationale |
|---|----------|-----------|---------|-----------|
| 1 | MUST-FIX | auth.py:42 | SQL injection in query builder | User input concatenated directly |
| 2 | IMPROVE  | api.py:88  | Missing error handling for timeout | Network call without try/except |
| 3 | NITPICK  | utils.py:15 | Rename variable for clarity | Style preference, current name is fine |
| 4 | DISMISSED | config.py:3 | "Unused import" | Import used by plugin system via dynamic loading |

Summary: 1 MUST-FIX, 1 IMPROVE, 1 NITPICK, 1 DISMISSED
```

#### E. Check Triage Early-Stop

After triage, check early-stop conditions:

1. **No actionable issues**: No MUST-FIX or IMPROVE findings → stop (report NITPICKs if any)
2. **All dismissed**: Every Codex finding was DISMISSED → stop (Codex has converged, nothing new)
3. **Codex said NO_SIGNIFICANT_ISSUES AND triage confirms**: → stop

If early-stopping:
```
✓ Early stop: {reason}
```

#### F. Fix Phase

Determine what to fix based on `FIX_LEVEL`:
- `must`: Fix only MUST-FIX
- `improve`: Fix MUST-FIX + IMPROVE (default)
- `all`: Fix MUST-FIX + IMPROVE + NITPICK

For issues to fix:

**If fixes are independent** (different files or non-overlapping regions):
Spawn parallel subagents, one per fix:

```python
Agent(
    prompt="""Fix the following issue in {file}:

Issue: {finding_description}
Severity: {severity}
Location: {file}:{line}

Read the file, understand the context, and apply a minimal targeted fix.
Do NOT refactor surrounding code. Fix only the identified issue.
After fixing, create an atomic commit with message:
  "fix({scope}): {short_description}"
""",
    subagent_type="general-purpose",
    description="Fix {severity}: {short_description}"
)
```

**If fixes overlap** (same file, adjacent lines):
Spawn a single subagent to handle them together to avoid conflicts.

Track each fix in `ALL_FIXES`:
```python
ALL_FIXES.append({
    "iteration": ITERATION,
    "severity": severity,
    "file": file,
    "description": description,
    "commit": commit_hash
})
```

#### G. Accumulate Hints & Loop

Add DISMISSED items to `DISMISSED_HINTS`:
```python
for finding in dismissed_findings:
    DISMISSED_HINTS.append({
        "suggestion": finding.description,
        "reason": finding.dismissal_reason
    })
```

Add NITPICKs to `ALL_NITPICKS` (for final report).
Add DISMISSED to `ALL_DISMISSED` (for transparency).

If any MUST-FIX or IMPROVE were fixed → loop (fixes may have introduced new issues).
If only NITPICK/DISMISSED remain → stop.

### 5. Final Report

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 IMPL RALPH REFACTOR COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Iterations: {ITERATION} of {MAX_ITERATIONS}
Early stopped: {Yes|No} — {reason if yes}

## Issues by Iteration

| Iter | MUST-FIX | IMPROVE | NITPICK | DISMISSED |
|------|----------|---------|---------|-----------|
| 1    | 2        | 3       | 1       | 2         |
| 2    | 0        | 1       | 0       | 1         |
| 3    | 0        | 0       | 0       | 0         |

## Fixes Applied ({N} total)

| # | Iter | Severity | File | Description | Commit |
|---|------|----------|------|-------------|--------|
| 1 | 1    | MUST-FIX | auth.py | SQL injection fix | abc1234 |
| 2 | 1    | IMPROVE  | api.py  | Added timeout handling | def5678 |
| ...

## Remaining NITPICKs (for your review)

{if ALL_NITPICKS is non-empty}
| # | File:Line | Suggestion |
|---|-----------|------------|
| 1 | utils.py:15 | Consider renaming `x` to `value` |
| ...
{else}
(none)
{end if}

## Dismissed Items Log

{if ALL_DISMISSED is non-empty}
| # | Iter | Suggestion | Reason Dismissed |
|---|------|------------|-----------------|
| 1 | 1    | "Unused import os" | Used by plugin dynamic loader |
| 2 | 1    | "Missing null check" | Type system guarantees non-null |
| ...
{else}
(none)
{end if}
```

If max iterations reached without convergence:
```
⚠ Max iterations reached. Review may not be complete.

Consider:
- Running with --max-iterations 5
- Running with --scope to focus on specific areas
- Manual review of remaining concerns
```

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Phase not found | Error with available phases |
| No code changes in range | Report "no changes found" and exit |
| Git ref not valid | Error with suggestion to check ref |
| Codex CLI not found | Error, suggest: `pip install openai-codex` |
| Codex timeout | Report, offer retry or skip iteration |
| Fix subagent fails | Report failure, continue to next fix, do not block loop |
| Merge conflict from parallel fixes | Re-run fixes sequentially for conflicting files |

---

## Example Session

```
User: /codex-impl-ralph-refactor 42

Claude:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CODEX IMPL RALPH REFACTOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Target: Phase 42
Changed files: 12
Max Iterations: 3
Fix Level: improve
Scope: all

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 REVIEW LOOP — Iteration 1 of 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Running Codex review...
✓ Codex review complete (8 findings)

◆ Triage Results (Iteration 1):

| # | Severity  | File:Line     | Finding                          |
|---|-----------|---------------|----------------------------------|
| 1 | MUST-FIX  | auth.py:42    | SQL injection in query builder   |
| 2 | MUST-FIX  | session.py:88 | Session token not invalidated    |
| 3 | IMPROVE   | api.py:156    | Missing timeout on HTTP call     |
| 4 | IMPROVE   | cache.py:23   | Race condition in cache write    |
| 5 | NITPICK   | utils.py:15   | Rename variable for clarity      |
| 6 | DISMISSED | config.py:3   | "Unused import" — used by plugin |
| 7 | DISMISSED | db.py:90      | "N+1 query" — already batched    |
| 8 | DISMISSED | test.py:5     | "Missing assertion" — uses pytest.raises |

Summary: 2 MUST-FIX, 2 IMPROVE, 1 NITPICK, 3 DISMISSED

◆ Fixing 4 issues (MUST-FIX + IMPROVE)...
  ✓ auth.py: SQL injection fix (commit abc1234)
  ✓ session.py: Token invalidation (commit def5678)
  ✓ api.py: Added request timeout (commit 9ab0123)
  ✓ cache.py: Lock around cache write (commit 456cdef)

◆ Accumulated 3 dismissed hints for next iteration

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 REVIEW LOOP — Iteration 2 of 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Running Codex review (with 3 dismissed hints)...
✓ Codex review complete (1 finding)

◆ Triage Results (Iteration 2):

| # | Severity | File:Line   | Finding                           |
|---|----------|-------------|-----------------------------------|
| 1 | IMPROVE  | auth.py:45  | Parameterized query missing index |

Summary: 0 MUST-FIX, 1 IMPROVE, 0 NITPICK, 0 DISMISSED

◆ Fixing 1 issue...
  ✓ auth.py: Added query parameter index (commit 789abcd)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 REVIEW LOOP — Iteration 3 of 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Running Codex review (with 3 dismissed hints)...
✓ Codex review complete

✓ Early stop: No MUST-FIX or IMPROVE issues found

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 IMPL RALPH REFACTOR COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Iterations: 3 of 3
Early stopped: Yes — no actionable issues in iteration 3

## Issues by Iteration

| Iter | MUST-FIX | IMPROVE | NITPICK | DISMISSED |
|------|----------|---------|---------|-----------|
| 1    | 2        | 2       | 1       | 3         |
| 2    | 0        | 1       | 0       | 0         |
| 3    | 0        | 0       | 0       | 0         |

## Fixes Applied (5 total)

| # | Iter | Severity | File       | Description               | Commit  |
|---|------|----------|------------|---------------------------|---------|
| 1 | 1    | MUST-FIX | auth.py    | SQL injection fix         | abc1234 |
| 2 | 1    | MUST-FIX | session.py | Token invalidation        | def5678 |
| 3 | 1    | IMPROVE  | api.py     | Added request timeout     | 9ab0123 |
| 4 | 1    | IMPROVE  | cache.py   | Lock around cache write   | 456cdef |
| 5 | 2    | IMPROVE  | auth.py    | Query parameter index     | 789abcd |

## Remaining NITPICKs (for your review)

| # | File:Line   | Suggestion                    |
|---|-------------|-------------------------------|
| 1 | utils.py:15 | Consider renaming `x` to `value` |

## Dismissed Items Log

| # | Iter | Suggestion              | Reason Dismissed                    |
|---|------|-------------------------|-------------------------------------|
| 1 | 1    | "Unused import"         | Used by plugin dynamic loader       |
| 2 | 1    | "N+1 query"             | Already batched via prefetch        |
| 3 | 1    | "Missing assertion"     | Uses pytest.raises context manager  |
```
