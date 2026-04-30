---
name: "agent-teams-impl-ralph-refactor"
description: "Review implemented code with Claude Code agent teams and iterative Ralph Loop — parallel reviewer agents find issues, Claude triages findings, fix agents resolve real issues, and dismissed false positives feed back as hints so reviewers stop repeating them."
---

# agent-teams-impl-ralph-refactor

Review implemented code with Claude Code agent teams and iterative Ralph Loop — parallel reviewer agents find issues, Claude triages findings, fix agents resolve real issues, and dismissed false positives feed back as hints so reviewers stop repeating them.

## Usage

```
/agent-teams-impl-ralph-refactor <phase-number|git-ref> [--max-iterations N] [--fix-level must|improve|all] [--scope path/] [--reviewer-model sonnet|opus]
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `phase-number` or `git-ref` | (required) | GSD phase number (e.g., 38) or git ref (e.g., `main`, `abc1234`) |
| `--max-iterations` | 3 | Maximum review-triage-fix loop iterations |
| `--fix-level` | improve | What to auto-fix: `must` (MUST-FIX only), `improve` (MUST-FIX + IMPROVE), `all` (everything including NITPICK) |
| `--scope` | (none) | Optional path filter to restrict review (e.g., `src/auth/`) |
| `--reviewer-model` | sonnet | Model for reviewer agents: `sonnet` (fast, cost-effective) or `opus` (deeper reasoning) |

## Examples

```
/agent-teams-impl-ralph-refactor 42                                  # Review phase 42 implementation
/agent-teams-impl-ralph-refactor 42 --max-iterations 5               # More iterations for thorough review
/agent-teams-impl-ralph-refactor main --scope src/core/              # Scoped review
/agent-teams-impl-ralph-refactor abc1234 --fix-level must            # Only auto-fix security/correctness bugs
/agent-teams-impl-ralph-refactor 38 --fix-level all                  # Auto-fix everything
/agent-teams-impl-ralph-refactor 42 --reviewer-model opus            # Use Opus for deeper review
```

## When to Use

Use this skill when:
- A GSD phase has been executed and you want to review the **implemented code** (not plans)
- You want Claude Code agent teams (parallel reviewer agents) to find bugs in code changes
- You want Claude to triage findings (dismiss false positives, assign severity)
- You want automatic fixing of real issues with iterative convergence
- You want a feedback loop that prevents reviewers from repeating dismissed suggestions
- You want an all-Claude solution without external CLI dependencies (no Codex/OpenAI needed)

Do NOT use this for reviewing plans — use `/codex-plan-ralph-refactor` for that.

---

## Severity Levels (Assigned by Orchestrator Claude, NOT Reviewer Agents)

The orchestrator triages every reviewer finding into one of four levels:

| Level | Meaning | Auto-Fix? | Action |
|-------|---------|-----------|--------|
| **MUST-FIX** | Security bugs, correctness errors, data corruption, crashes | Always | Fix immediately |
| **IMPROVE** | Genuine quality gains — edge cases, error handling, API misuse, logic clarity | Default yes | Fix — if it genuinely makes code better |
| **NITPICK** | Purely subjective style preferences, cosmetic-only changes | Only with `--fix-level all` | Report for user to decide |
| **DISMISSED** | False positive, misleading, or inapplicable suggestion | Never | Add to hint context for next loop |

**Triage bar**: IMPROVE means "does this genuinely make the codebase better?" If yes, fix it. If it's just taste, it's a NITPICK.

---

## Agent Strategy

Maximize parallelism at every stage. The orchestrator (main Claude context) coordinates; specialist agents do the work.

### Agent Roles

| Role | Agent Type | Model | When Used |
|------|-----------|-------|-----------|
| **Reviewer Agent** | `general-purpose` subagent | `--reviewer-model` (default sonnet) | Each angle cluster gets its own reviewer |
| **Triage Analyst** | `general-purpose` subagent | sonnet | Evaluates a batch of findings against actual code |
| **Fix Engineer** | `general-purpose` subagent | sonnet | Applies a targeted fix + atomic commit |
| **Verification Engineer** | `general-purpose` subagent | sonnet | Confirms fix correctness after application |

### Model Selection Rationale

- **Reviewer agents**: Default to Sonnet — code review is well-scoped with clear instructions. Use `--reviewer-model opus` for subtle/complex codebases where deeper reasoning pays off.
- **Triage agents**: Always Sonnet — evaluating "is this a real bug?" against actual code is a focused, well-defined task.
- **Fix agents**: Always Sonnet — each fix is a targeted, well-scoped edit.
- **Verification agents**: Always Sonnet — checking "did the fix work?" is straightforward.
- **Orchestrator**: Opus (the main Claude session) handles severity assignment, loop decisions, and conflict resolution.

### Parallelization Points

```
Iteration 1 (broad sweep):
├── Review: 3 parallel reviewer agents, each with different angle cluster
│   ├── Reviewer A: Security + Correctness
│   ├── Reviewer B: Performance + Concurrency + Resource Leaks
│   └── Reviewer C: Maintainability + Edge Cases + Error Recovery
├── Triage: parallel subagents (one per reviewer's findings)
│   ├── Triage Agent A: evaluate findings from Reviewer A
│   ├── Triage Agent B: evaluate findings from Reviewer B
│   └── Triage Agent C: evaluate findings from Reviewer C
├── Fix: parallel subagents (one per independent fix)
│   ├── Fix Agent 1: auth.py fix
│   ├── Fix Agent 2: session.py fix
│   └── Fix Agent 3: api.py + cache.py fixes (same module, sequential)
└── Verify: parallel subagents (one per fix)
    ├── Verify Agent 1: confirm auth.py fix
    └── Verify Agent 2: confirm session.py fix

Iteration 2+ (targeted):
├── 1-2 reviewer agents (focused on uncovered angles + re-check fixed areas)
├── Triage inline if few findings, subagent if 5+
├── Fix: parallel subagents
└── Verify: parallel subagents
```

### When to Use Team Agents vs Inline

| Finding count | Triage approach |
|---------------|----------------|
| 1-4 findings | Inline — orchestrator triages directly (fast, no overhead) |
| 5-9 findings | 2 triage subagents, split by file cluster |
| 10+ findings | 3+ triage subagents, split by category (Security, Perf, Maintainability) |

### Multi-Angle Strategy (Iteration 1 Only)

On the first iteration, spawn **3 parallel reviewer agents** instead of one broad call. Each focuses on a different angle cluster:

```python
# Spawn in parallel — all three run concurrently
Agent(
    prompt="<REVIEW_PROMPT focused on Security + Correctness>",
    subagent_type="general-purpose",
    model=REVIEWER_MODEL,  # default "sonnet"
    description="Review: Security+Correctness"
)
Agent(
    prompt="<REVIEW_PROMPT focused on Performance + Concurrency + Resources>",
    subagent_type="general-purpose",
    model=REVIEWER_MODEL,
    description="Review: Perf+Concurrency"
)
Agent(
    prompt="<REVIEW_PROMPT focused on Maintainability + Edge Cases + Error Recovery>",
    subagent_type="general-purpose",
    model=REVIEWER_MODEL,
    description="Review: Maintain+EdgeCases"
)
```

Each agent reads the changed files directly (using Read/Grep tools available to general-purpose agents) and produces structured findings. The orchestrator merges all findings, deduplicates, then proceeds to triage.

**After iteration 1**: Use 1-2 reviewer agents targeting uncovered angles. Full 3-way split is too expensive for diminishing returns in later iterations.

---

## Workflow

### 1. Parse Arguments

Extract from user command:
- `TARGET`: Phase number or git ref (required)
- `MAX_ITERATIONS`: Default 3, override with `--max-iterations N`
- `FIX_LEVEL`: Default "improve", choices: must, improve, all
- `SCOPE`: Optional path filter
- `REVIEWER_MODEL`: Default "sonnet", override with `--reviewer-model opus`

Determine target type:
1. If numeric: treat as GSD phase number
2. Otherwise: treat as git ref

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
COVERED_ANGLES = []        # Categories reviewers have already explored
ITERATION = 0
ALL_FIXES = []             # Track all fixes applied
ALL_NITPICKS = []          # Track nitpicks for final report
ALL_DISMISSED = []         # Track dismissed items for transparency
PREV_HAD_FIXES = False     # Did previous iteration apply fixes?
PREV_ALL_DISMISSED = False # Were all previous findings dismissed?
```

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 AGENT TEAMS IMPL RALPH REFACTOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Target: {TARGET} ({type: phase|git-ref})
Reviewer Model: {REVIEWER_MODEL}
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

#### A. Build Reviewer Agent Prompts

Each reviewer agent gets a prompt containing:

```
You are a senior code reviewer. Review the following code changes for issues in your assigned focus areas.

## Your Focus Areas
{ANGLE_CLUSTER — e.g., "Security + Correctness" or "Performance + Concurrency + Resource Leaks"}

## Changed Files
{CHANGED_FILES list with full paths}

## Diff Context
{DIFF_CONTENT — the git diff for reference}

## Instructions
- Read each changed file using the Read tool to see the full context (not just the diff)
- Focus ONLY on your assigned areas — do not duplicate other reviewers' work
- For each finding: cite exact file:line, describe the issue, explain why it matters, suggest a fix
- Categorize each finding: Security, Correctness, Performance, Concurrency, Resource Leaks, Maintainability, Edge Cases, Error Recovery
- If no significant issues are found in your focus areas, state "NO_SIGNIFICANT_ISSUES"
- Be precise — false positives waste time. Only report issues you are confident about.

{HINT_BLOCK if DISMISSED_HINTS is non-empty}

## Output Format

Return findings as a structured list:

### Finding 1
- **Category**: {category}
- **Severity**: HIGH/MEDIUM/LOW (your assessment — orchestrator will re-triage)
- **File:Line**: {file}:{line}
- **Issue**: {description}
- **Why it matters**: {impact}
- **Suggested fix**: {fix description}

### Finding 2
...

(or "NO_SIGNIFICANT_ISSUES" if none found)
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

The `ANGLE_EXPANSION_BLOCK` (only included after iteration 1, added to all reviewer prompts):

```
## Expand Your Review Angles

Prior iterations already covered these categories:
{for each angle in COVERED_ANGLES}
- {angle}
{end for}

You MUST explore NEW angles not yet covered. Consider:
- Concurrency & thread safety
- Resource leaks (file handles, connections, memory)
- Error recovery & partial failure states
- API contract violations (pre/post conditions)
- Edge cases (empty inputs, boundary values, unicode, large payloads)
- Dependency version compatibility
- Configuration & environment assumptions
- Logging & observability gaps
- Backward compatibility breaks
- Type safety & implicit conversions

Focus on angles NOT in the "already covered" list above.
If you have genuinely exhausted all angles, state "NO_SIGNIFICANT_ISSUES".
```

#### B. Run Reviewer Agents

**Iteration 1: Multi-angle parallel review** — spawn 3 parallel reviewer agents:

```python
# All three launched in a single message — true parallel execution
Agent(
    prompt="<REVIEW_PROMPT with focus: Security + Correctness>",
    subagent_type="general-purpose",
    model=REVIEWER_MODEL,
    description="Review: Security+Correctness"
)
Agent(
    prompt="<REVIEW_PROMPT with focus: Performance + Concurrency + Resource Leaks>",
    subagent_type="general-purpose",
    model=REVIEWER_MODEL,
    description="Review: Perf+Concurrency"
)
Agent(
    prompt="<REVIEW_PROMPT with focus: Maintainability + Edge Cases + Error Recovery>",
    subagent_type="general-purpose",
    model=REVIEWER_MODEL,
    description="Review: Maintain+EdgeCases"
)
```

**Iteration 2+: Targeted review** — spawn 1-2 reviewer agents:

| Condition | Strategy | Rationale |
|-----------|----------|-----------|
| Previous iter applied fixes | 1 agent: re-check fixed files + uncovered angles | Verify fixes, catch regressions |
| Previous iter all DISMISSED/NITPICK | 1-2 agents: fresh angles only | Previous angles exhausted |
| Significant uncovered angles remain | 2 agents: split remaining angles | Parallel coverage of new ground |

Display:
```
◆ Reviewer strategy: {N} agents — {reason}
```

Collect `REVIEWER_OUTPUT` from all agents. Merge findings, deduplicate (same file:line + same issue = duplicate).

#### C. Check Early-Stop (Pre-Triage)

Parse all reviewer outputs:
- If ALL reviewers report `NO_SIGNIFICANT_ISSUES`: proceed to triage to confirm, but flag likely early-stop

#### D. Claude Triage (Inline or Subagent Team)

**Choose triage approach based on finding count** (see Agent Strategy above):

**Inline (1-4 findings)** — Claude analyzes directly in main context:

1. **Read referenced files**: For each file:line cited by reviewers, read the actual code
2. **Evaluate each finding**: For every suggestion:
   - Is the code actually doing what the reviewer claims? (Check the real code, not just the diff)
   - Is this a real bug, a genuine improvement, a style preference, or a false positive?
   - Does the project's existing patterns/conventions make this suggestion inapplicable?
3. **Assign severity**: MUST-FIX / IMPROVE / NITPICK / DISMISSED
4. **For DISMISSED**: Record the suggestion text and the reason for dismissal
5. **Track covered angles**: Extract the categories reviewers explored this iteration

**Subagent team (5+ findings)** — Spawn parallel triage agents:

```python
# Split findings into clusters (by file group or category)
# Spawn one triage agent per cluster — all run in parallel

Agent(
    prompt="""You are a Triage Analyst. Evaluate these code review findings against the actual code.

For each finding:
1. Read the cited file:line using the Read tool
2. Determine if the code actually has the issue the reviewer claims
3. Assign severity: MUST-FIX / IMPROVE / NITPICK / DISMISSED
4. For DISMISSED: explain why it's a false positive

Findings to evaluate:
{cluster_findings}

Return a structured table:
| # | Severity | File:Line | Finding | Rationale |
""",
    subagent_type="general-purpose",
    model="sonnet",
    description="Triage: {cluster_label}"
)
```

The orchestrator merges triage results from all agents, deduplicates, and builds the unified triage table.

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
2. **All dismissed**: Every finding was DISMISSED → stop (reviewers have converged, nothing new)
3. **All reviewers said NO_SIGNIFICANT_ISSUES AND triage confirms**: → stop

If early-stopping:
```
✓ Early stop: {reason}
```

#### F. Fix Phase (Parallel Subagents)

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
    model="sonnet",
    description="Fix {severity}: {short_description}"
)
```

**If fixes overlap** (same file, adjacent lines):
Spawn a single subagent to handle them together to avoid conflicts.

**After all fix agents complete — spawn parallel verification agents:**

```python
# One verification agent per fix, all run in parallel
Agent(
    prompt="""Verify the fix applied in commit {commit_hash}:

Original issue: {finding_description}
File: {file}:{line}

1. Read the file at the fixed location
2. Confirm the issue is actually resolved
3. Check the fix didn't introduce new problems (regressions, broken imports, etc.)
4. Return: VERIFIED / REGRESSION_FOUND / INCOMPLETE_FIX with explanation
""",
    subagent_type="general-purpose",
    model="sonnet",
    description="Verify fix: {short_description}"
)
```

If any verification returns REGRESSION_FOUND or INCOMPLETE_FIX, add it to the next iteration's fix queue.

Track each fix in `ALL_FIXES`:
```python
ALL_FIXES.append({
    "iteration": ITERATION,
    "severity": severity,
    "file": file,
    "description": description,
    "commit": commit_hash,
    "verified": verification_result
})
```

#### G. Accumulate State & Loop

Add DISMISSED items to `DISMISSED_HINTS`:
```python
for finding in dismissed_findings:
    DISMISSED_HINTS.append({
        "suggestion": finding.description,
        "reason": finding.dismissal_reason
    })
```

Update session state for next iteration:
```python
PREV_HAD_FIXES = len(fixes_applied_this_iteration) > 0
PREV_ALL_DISMISSED = all(f.severity == "DISMISSED" for f in findings) or \
                     all(f.severity in ("DISMISSED", "NITPICK") for f in findings)
```

Add covered angles from this iteration's findings:
```python
for finding in all_findings_this_iteration:
    angle = f"{finding.category}: {finding.short_description}"
    if angle not in COVERED_ANGLES:
        COVERED_ANGLES.append(angle)
```

Add NITPICKs to `ALL_NITPICKS` (for final report).
Add DISMISSED to `ALL_DISMISSED` (for transparency).

If any MUST-FIX or IMPROVE were fixed → loop (fixes may have introduced new issues).
If only NITPICK/DISMISSED remain → stop.

### 5. Final Report

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 AGENT TEAMS IMPL RALPH REFACTOR COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Iterations: {ITERATION} of {MAX_ITERATIONS}
Early stopped: {Yes|No} — {reason if yes}
Reviewer model: {REVIEWER_MODEL}

## Issues by Iteration

| Iter | Reviewers | MUST-FIX | IMPROVE | NITPICK | DISMISSED |
|------|-----------|----------|---------|---------|-----------|
| 1    | 3         | 2        | 3       | 1       | 2         |
| 2    | 1         | 0        | 1       | 0       | 1         |
| 3    | 1         | 0        | 0       | 0       | 0         |

## Angles Explored

{COVERED_ANGLES list}

## Fixes Applied ({N} total)

| # | Iter | Severity | File | Description | Commit | Verified |
|---|------|----------|------|-------------|--------|----------|
| 1 | 1    | MUST-FIX | auth.py | SQL injection fix | abc1234 | VERIFIED |
| 2 | 1    | IMPROVE  | api.py  | Added timeout handling | def5678 | VERIFIED |
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
- Running with --reviewer-model opus for deeper analysis
- Manual review of remaining concerns
```

---

## Key Differences from codex-impl-ralph-refactor

| Aspect | codex-impl-ralph-refactor | agent-teams-impl-ralph-refactor |
|--------|--------------------------|--------------------------------|
| **Review engine** | Codex CLI (`codex exec`) | Claude Code agent teams (Agent tool) |
| **External deps** | Requires Codex CLI + OpenAI API key | None — all Claude, works out of the box |
| **Session resume** | Codex session resume mechanism | Fresh agents per iteration (stateless but context-rich via prompts) |
| **Provider** | `mify` flag for Azure OpenAI proxy | N/A — uses Claude models directly |
| **Model control** | Fixed gpt-5.4 | `--reviewer-model` flag (sonnet/opus) |
| **Code access** | Codex reads files via its sandbox | Agents read files via Read/Grep tools |
| **Parallelism** | Codex calls + subagents | Pure agent teams at every stage |

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Phase not found | Error with available phases |
| No code changes in range | Report "no changes found" and exit |
| Git ref not valid | Error with suggestion to check ref |
| Reviewer agent fails | Log error, continue with other reviewers' findings |
| Fix subagent fails | Report failure, continue to next fix, do not block loop |
| Merge conflict from parallel fixes | Re-run fixes sequentially for conflicting files |
| All reviewer agents return empty | Early-stop — code is clean |

---

## Example Session

```
User: /agent-teams-impl-ralph-refactor 42

Claude:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 AGENT TEAMS IMPL RALPH REFACTOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Target: Phase 42
Reviewer Model: sonnet
Changed files: 12
Max Iterations: 3
Fix Level: improve
Scope: all

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 REVIEW LOOP — Iteration 1 of 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Reviewer strategy: 3 agents — broad sweep (Security+Correctness, Perf+Concurrency, Maintain+EdgeCases)
◆ Running parallel reviewer agents...
✓ All reviewers complete (8 findings across 3 agents)

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
Angles covered: Security (injection, session), Performance (query), Correctness (timeout, race)

◆ Fixing 4 issues (MUST-FIX + IMPROVE)...
  ✓ auth.py: SQL injection fix (commit abc1234) — VERIFIED
  ✓ session.py: Token invalidation (commit def5678) — VERIFIED
  ✓ api.py: Added request timeout (commit 9ab0123) — VERIFIED
  ✓ cache.py: Lock around cache write (commit 456cdef) — VERIFIED

◆ Accumulated 3 dismissed hints for next iteration

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 REVIEW LOOP — Iteration 2 of 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Reviewer strategy: 1 agent — re-check fixed files + uncovered angles
◆ Running reviewer agent (with 3 dismissed hints, exploring new angles)...
✓ Review complete (2 findings)

◆ Triage Results (Iteration 2):

| # | Severity | File:Line    | Finding                                  |
|---|----------|--------------|------------------------------------------|
| 1 | IMPROVE  | auth.py:45   | Parameterized query missing index        |
| 2 | IMPROVE  | cache.py:30  | Lock not released in exception path      |

Summary: 0 MUST-FIX, 2 IMPROVE, 0 NITPICK, 0 DISMISSED
Angles covered: +Error Recovery (exception path)

◆ Fixing 2 issues...
  ✓ auth.py: Added query parameter index (commit 789abcd) — VERIFIED
  ✓ cache.py: Added finally block for lock release (commit bcd2345) — VERIFIED

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 REVIEW LOOP — Iteration 3 of 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Reviewer strategy: 1 agent — final sweep of remaining angles
◆ Running reviewer agent...

✓ Early stop: No MUST-FIX or IMPROVE issues found

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 AGENT TEAMS IMPL RALPH REFACTOR COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Iterations: 3 of 3
Early stopped: Yes — no actionable issues in iteration 3
Reviewer model: sonnet

## Issues by Iteration

| Iter | Reviewers | MUST-FIX | IMPROVE | NITPICK | DISMISSED |
|------|-----------|----------|---------|---------|-----------|
| 1    | 3         | 2        | 2       | 1       | 3         |
| 2    | 1         | 0        | 2       | 0       | 0         |
| 3    | 1         | 0        | 0       | 0       | 0         |

## Angles Explored

Security (injection, session), Performance (query), Correctness (timeout, race),
Error Recovery (exception path), Resource Leaks, Edge Cases — all clean by iter 3

## Fixes Applied (6 total)

| # | Iter | Severity | File       | Description               | Commit  | Verified |
|---|------|----------|------------|---------------------------|---------|----------|
| 1 | 1    | MUST-FIX | auth.py    | SQL injection fix         | abc1234 | VERIFIED |
| 2 | 1    | MUST-FIX | session.py | Token invalidation        | def5678 | VERIFIED |
| 3 | 1    | IMPROVE  | api.py     | Added request timeout     | 9ab0123 | VERIFIED |
| 4 | 1    | IMPROVE  | cache.py   | Lock around cache write   | 456cdef | VERIFIED |
| 5 | 2    | IMPROVE  | auth.py    | Query parameter index     | 789abcd | VERIFIED |
| 6 | 2    | IMPROVE  | cache.py   | Lock release in finally   | bcd2345 | VERIFIED |

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
