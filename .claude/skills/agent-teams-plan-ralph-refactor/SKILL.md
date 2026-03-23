# agent-teams-plan-ralph-refactor

Review GSD phase plans with Claude Code agent teams and auto-refactor using Ralph Loop with early-stop detection. Parallel reviewer agents find design issues, the orchestrator triages, planner agents revise, and a checker agent verifies.

## Usage

```
/agent-teams-plan-ralph-refactor <phase-number> [--max-iterations N] [--focus critical|major|all] [--reviewer-model sonnet|opus]
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `phase-number` | (required) | Phase to review (e.g., 38) |
| `--max-iterations` | 3 | Maximum Ralph loop iterations |
| `--focus` | all | Issue severity to focus on |
| `--reviewer-model` | sonnet | Model for reviewer agents: `sonnet` (fast) or `opus` (deeper reasoning) |

## Examples

```
/agent-teams-plan-ralph-refactor 38                           # Default: 3 iterations, all issues
/agent-teams-plan-ralph-refactor 38 --max-iterations 5        # More iterations
/agent-teams-plan-ralph-refactor 38 --focus critical          # Critical only
/agent-teams-plan-ralph-refactor 38 --reviewer-model opus     # Use Opus for deeper review
```

## When to Use

Use this skill when:
- You have existing GSD phase plans that need review
- You want Claude Code agent teams (parallel reviewer agents) to find design issues
- You want automatic plan refactoring via Ralph Loop
- You want early-stop when no critical/major issues remain
- You want an all-Claude solution without external CLI dependencies (no Codex/OpenAI needed)

Do NOT use this for reviewing implemented code — use `/agent-teams-impl-ralph-refactor` for that.

---

## Agent Strategy

Maximize parallelism at every stage. The orchestrator (main Claude context) coordinates; specialist agents do the work.

### Agent Roles

| Role | Agent Type | Model | When Used |
|------|-----------|-------|-----------|
| **Reviewer Agent** | `general-purpose` subagent | `--reviewer-model` (default sonnet) | Each angle cluster gets its own reviewer |
| **Plan Reviser** | `general-purpose` subagent | sonnet | Revises plan files to address findings |
| **Plan Checker** | `gsd-plan-checker` subagent | sonnet | Verifies revised plans meet requirements |

### Model Selection Rationale

- **Reviewer agents**: Default to Sonnet — plan review has clear, structured instructions. Use `--reviewer-model opus` for complex multi-plan phases where cross-plan reasoning is critical.
- **Plan Reviser agents**: Always Sonnet — each reviser works on a specific plan file with clear findings to address.
- **Plan Checker**: Always Sonnet (gsd-plan-checker subagent) — verification is a well-scoped task.
- **Orchestrator**: Opus (the main Claude session) handles deduplication, loop decisions, stall detection, and state persistence.

### Parallelization Points

```
Iteration 1 (broad sweep):
├── Review: 3 parallel reviewer agents, each with different angle cluster
│   ├── Reviewer A: Safety + Correctness + Error Handling
│   ├── Reviewer B: Architecture + Coupling + Integration Points
│   └── Reviewer C: Test Coverage + Edge Cases + Scalability
├── Planner: parallel subagents if multiple PLAN.md files
│   ├── Planner Agent 1: revise PLAN-task-A.md
│   └── Planner Agent 2: revise PLAN-task-B.md
└── Checker: runs after all planners complete

Iteration 2+ (targeted):
├── 1-2 reviewer agents (focused on uncovered angles + re-check revised areas)
├── Planner: single subagent (targeted revisions)
└── Checker: single subagent
```

### Multi-Angle Strategy (Iteration 1 Only)

On the first iteration, spawn **3 parallel reviewer agents** instead of one broad review. Each focuses on a different design angle cluster:

```python
# Spawn in parallel — all three run concurrently
Agent(
    prompt="<REVIEW_PROMPT focused on Cross-plan contract consistency, component boundaries>",
    subagent_type="general-purpose",
    model=REVIEWER_MODEL,  # default "sonnet"
    description="Review: Contracts+Boundaries"
)
Agent(
    prompt="<REVIEW_PROMPT focused on Phase sequencing, dependencies, integration points>",
    subagent_type="general-purpose",
    model=REVIEWER_MODEL,
    description="Review: Sequencing+Integration"
)
Agent(
    prompt="<REVIEW_PROMPT focused on Error strategies, observability gaps, recovery>",
    subagent_type="general-purpose",
    model=REVIEWER_MODEL,
    description="Review: ErrorStrategy+Observability"
)
```

Each agent reads the plan files directly (using Read tool) and produces structured findings with `[CRITICAL]`/`[MAJOR]`/`[MINOR]` tags and `[ANGLE_COVERED: ...]` tags.

The orchestrator deduplicates merged findings:

```
Deduplicate these structured findings from 3 parallel reviews. Each finding is one line
starting with [CRITICAL], [MAJOR], or [MINOR]. Merge lines that describe the same design
issue (even if worded differently) into a single canonical line. Preserve all unique findings.
Keep all [ANGLE_COVERED: ...] tags (dedup those too).

Agent A findings:
{agent_a_tagged_lines}

Agent B findings:
{agent_b_tagged_lines}

Agent C findings:
{agent_c_tagged_lines}

Output format: one finding per line, [SEVERITY] prefix, then [ANGLE_COVERED: ...] tags at end.
```

Display: `◆ Dedup: {raw_total} findings → {deduped_total} unique`

**After iteration 1**: Use 1-2 reviewer agents targeting uncovered angles.

---

## Workflow

### 1. Parse Arguments

Extract from user command:
- `PHASE`: Phase number (required)
- `MAX_ITERATIONS`: Default 3, override with `--max-iterations N`
- `FOCUS`: Default "all", choices: critical, major, all
- `REVIEWER_MODEL`: Default "sonnet", override with `--reviewer-model opus`

### 2. Validate Phase

Check that:
- `.planning/phases/` exists
- Phase directory `{PHASE}-*` exists
- PLAN.md files exist in phase directory

If not found, error with available phases.

### 3. Ralph Loop (1 to MAX_ITERATIONS)

#### Load Persistent State

Before initializing, check for a state file from previous runs:

```
STATE_FILE = .planning/phases/{PHASE_DIR}/{PHASE}-AGENT-REVIEW-STATE.md
```

If it exists, read it and extract:
- `COVERED_ANGLES`: list of angles already explored in prior runs
- Previously resolved findings (for context, not re-flagging)

Display if loaded:
```
◆ Loaded prior review state: {N} angles already covered from previous run(s)
  Angles: {comma-joined list}
```

If state file does not exist, start fresh.

Initialize loop state:
```python
COVERED_ANGLES = [...loaded from file, or []]   # Pre-populated if prior run exists
PREV_HAD_FIXES = False          # Did previous iteration actually change plan files?
PREV_ITER_FINGERPRINTS = set()  # Normalized finding descriptions from last iter (stall detection)
STALL_COUNT = 0                 # Consecutive iterations with identical findings
```

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 AGENT TEAMS PLAN RALPH REFACTOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase: {PHASE}
Reviewer Model: {REVIEWER_MODEL}
Max Iterations: {MAX_ITERATIONS}
Focus: {FOCUS}
```

For each iteration:

#### A. Run Reviewer Agents (Multi-Angle on Iter 1)

**Iteration 1: Multi-angle parallel review** — spawn 3 parallel reviewer agents.

**Iteration 2+: Targeted review** with strategy auto-selection:

| Priority | Condition | Strategy | Rationale |
|----------|-----------|----------|-----------|
| 1 | Every 3rd iteration (iter % 3 == 0) | 2 agents, fresh angles | Diversity injection |
| 2 | Previous iter found only MINOR or nothing | 1-2 agents, new angles | Previous angles exhausted |
| 3 | Previous iter revised plans (`PREV_HAD_FIXES`) | 1 agent, re-check + new | Verify revisions, catch regressions |
| 4 | Default | 1 agent, new angles | Explore remaining ground |

Display:
```
◆ Reviewer strategy: {N} agents — {reason}
```

**Build the reviewer prompt** for each agent:

```
You are reviewing GSD phase PLAN files in .planning/phases/{PHASE}-*/.

## Your Focus Areas
{ANGLE_CLUSTER — e.g., "Cross-plan contract consistency, component boundaries"}

## CRITICAL: What these plan files are

These are DESIGN documents, not implementation code. They contain:
- Objectives and requirements
- Component responsibilities and boundaries
- Illustrative pseudocode showing intent (NOT contracts — actual names/types will differ)
- Task breakdowns and dependencies between plans

## What to flag (design-level concerns only)

{FOCUS_PROMPT}

**Each finding MUST start with its severity tag on the same line.** Required format:

```
[CRITICAL] <description>
[MAJOR] <description>
[MINOR] <description>
```

Severity definitions:
- [CRITICAL]: The design cannot work as described — contradictory component contracts, missing
  required dependencies between plans, impossible sequencing, architectural blockers that will
  cause the implementation to fail regardless of how the pseudocode is written
- [MAJOR]: Significant design gaps — missing error recovery *strategy* (not missing try/catch),
  unclear ownership of shared state, integration points not addressed, cross-plan contract
  inconsistencies where two plans define the *same named interface* differently
- [MINOR]: Ambiguity that could lead the executor astray, undocumented assumptions, unclear
  phase sequencing

## What NOT to flag

Do NOT flag any of the following — they are normal properties of a design document:
- Specific attribute or variable names in pseudocode (these are illustrative; actual names are decided at implementation time)
- Exact method signatures in pseudocode class sketches (sketches show design intent, not final API)
- Specific string/enum literal values used in pseudocode examples
- Implementation details that could reasonably be resolved during coding without changing the design
- Missing methods/fields in pseudocode sketches (sketches are intentionally incomplete)
- Style, documentation hygiene, or minor naming suggestions
- Any issue that would only matter if the pseudocode were executed verbatim (it won't be)

## Instructions

1. Read ALL plan files in the phase directory using the Read tool
2. Focus ONLY on your assigned areas — do not duplicate other reviewers' work
3. For each finding: cite which plan file(s), what design constraint or interface is broken, why it blocks/degrades implementation
4. Be precise — false positives waste time. Only report issues you are confident about.

## Reporting

For each CRITICAL or MAJOR finding, state:
- Which plan file(s) are affected
- What design constraint or interface is broken
- Why this blocks or degrades the implementation outcome

If no CRITICAL or MAJOR design issues found, state 'NO_CRITICAL_MAJOR_ISSUES'.

At the end of your response, list every design angle you examined using this exact format
(one per line, no extra text on the same line):

[ANGLE_COVERED: Cross-plan contracts]
[ANGLE_COVERED: Error recovery strategy]
[ANGLE_COVERED: Phase sequencing]

Use concise angle names. This structured output is machine-parsed.

{HINT_BLOCK if DISMISSED_HINTS is non-empty}

{ANGLE_EXPANSION_BLOCK if COVERED_ANGLES is non-empty}
```

FOCUS_PROMPT mapping:
- `critical`: "Look only for CRITICAL design blockers: contradictory contracts between plans, impossible phase sequencing, missing dependencies that make the design unimplementable"
- `major`: "Look for CRITICAL and MAJOR design gaps: missing error recovery strategies, cross-plan interface inconsistencies, unclear component ownership of shared state, integration points not addressed"
- `all`: "Look for all design concerns — component boundaries, cross-plan contracts, error strategies, phase dependencies, test coverage strategy, and observability gaps"

The `ANGLE_EXPANSION_BLOCK` (only included after iteration 1):

```
## Expand Your Review Angles

Prior iterations already covered these design angles:
{for each angle in COVERED_ANGLES}
- {angle}
{end for}

You MUST explore NEW design angles not yet covered. Consider:
- Component ownership gaps: who owns shared state? who is responsible for cleanup?
- Cross-plan contract consistency: do the plans agree on interfaces they share?
- Missing error strategy: what happens when a key integration point fails — is the strategy defined?
- Phase sequencing: can plans execute in the declared wave order given their dependencies?
- Test coverage strategy: are the test plans sufficient to verify the design goals?
- Backward compatibility: does this design break existing callers in ways not addressed?
- Observability: is there a plan for debugging failures in the implemented system?
- Dependency risks: are external dependencies assumed available without a fallback strategy?

Focus on DESIGN angles not yet covered. Do NOT revisit pseudocode implementation details.
If you have genuinely exhausted all design angles, state 'NO_CRITICAL_MAJOR_ISSUES'.
```

Collect outputs from all reviewer agents. Merge and deduplicate findings.

#### B. Check Early-Stop & Track Angles

Parse reviewer outputs — **tag counts are authoritative and override summary strings**:

1. Count `[CRITICAL]` and `[MAJOR]` tag occurrences
2. Extract `[ANGLE_COVERED: ...]` structured tags → add to `COVERED_ANGLES` **only if that
   angle produced zero CRITICAL/MAJOR findings** (a reviewed-but-failing angle is not "covered"):
   ```python
   for angle in extracted_angles:
       angle_findings = [f for f in findings if angle_is_relevant(f, angle)]
       if not any(f.severity in ("CRITICAL", "MAJOR") for f in angle_findings):
           COVERED_ANGLES.add(angle)  # clean — skip on future runs
       # else: angle has open issues, do NOT mark covered
   ```
3. Determine early-stop (scope-aware):
   ```python
   if FOCUS == "critical":
       stop_condition = (critical_count == 0)  # major not in scope
   else:
       stop_condition = (critical_count == 0 and major_count == 0)
   ```
   - If stop condition met → early stop
   - If output contains "NO_CRITICAL_MAJOR_ISSUES" but in-scope tags present: **ignore string**,
     log `⚠ Reviewer output inconsistent: claimed no issues but flagged N finding(s). Using tag counts.`

Display findings:
```
◆ Review Findings:
- [CRITICAL] ...
- [MAJOR] ...

Issues found: X critical, Y major, Z minor
```

#### C. Spawn Planner(s) (if issues remain)

**Route findings to plan files first** — extract a `file → [findings]` mapping before spawning planners:

```python
FILE_FINDINGS = defaultdict(list)
for finding in critical_major_findings:
    for plan_file in extract_affected_files(finding):
        FILE_FINDINGS[plan_file].append(finding)
```

**If multiple plan files have findings** — spawn parallel planner subagents:

```python
Agent(
    prompt=f"""Revise {plan_file} to address these findings:

{chr(10).join(f'- {f}' for f in FILE_FINDINGS[plan_file])}

Instructions:
1. Read the plan file using the Read tool
2. Update plans to address findings (CRITICAL first, then MAJOR)
3. Make structural design changes — close the actual gap, don't just add an explanatory note.
   Examples of structural fixes:
   - Missing cross-plan contract: add an explicit interfaces section or update must_haves to align both sides
   - Missing error strategy: add a decision (e.g. "on planner timeout: skip position and log SKIP") not just "consider error handling"
   - Ambiguous component ownership: explicitly name the owner in the relevant task description
   If pseudocode is genuinely misleading, correct the pseudocode — but do NOT add boilerplate notes defending every pseudocode detail
4. Anti-regression rule: Do NOT remove existing design constraints, interface definitions, or error strategies. If two plans conflict, reconcile by aligning both sides — never by deleting from one.
5. Return:
   ## PLANNING COMPLETE

   ## Changes Made
   - {plan_file}: {what was added/modified} — addresses finding: {finding short description}
""",
    subagent_type="general-purpose",
    model="sonnet",
    description=f"Revise {plan_file}"
)
```

**If phase has a single PLAN.md** — spawn one planner subagent with all findings.

#### D. Verify Planner Changes + Stall Detection

Confirm the planner made real changes:

```bash
git diff --name-only -- '.planning/phases/{PHASE_DIR}/'
```

- If diff is **non-empty**: set `PREV_HAD_FIXES = True`
- If diff is **empty**: set `PREV_HAD_FIXES = False`, log `⚠ Planner claimed completion but no plan files changed.`

**Then run stall detection**:

```python
THIS_ITER_FINGERPRINTS = set(normalize(f) for f in critical_major_findings)
if THIS_ITER_FINGERPRINTS and THIS_ITER_FINGERPRINTS == PREV_ITER_FINGERPRINTS:
    STALL_COUNT += 1
else:
    STALL_COUNT = 0
PREV_ITER_FINGERPRINTS = THIS_ITER_FINGERPRINTS

if STALL_COUNT >= 2:
    abort: "Planner unable to resolve these findings after 2 attempts. Manual review needed:\n{stuck_findings}"
```

#### E. Spawn Plan-Checker

Use Agent tool to spawn checker (after all planners complete and diff confirms changes):

```python
Agent(
    prompt=f"""Verify Phase {PHASE} plans address the requirements.

Specifically confirm these findings were resolved:
{chr(10).join(f'- {f}' for f in critical_major_findings)}

For each finding, state: RESOLVED or STILL_PRESENT with explanation.
Then return "## VERIFICATION PASSED" if all resolved, or "## ISSUES FOUND" if any remain.""",
    subagent_type="gsd-plan-checker",
    model="sonnet",
    description=f"Verify Phase {PHASE} plans"
)
```

Checker should return:
- "## VERIFICATION PASSED" with per-finding RESOLVED confirmations → **continue to next iteration**
- "## ISSUES FOUND" with structured list of what's still missing → **add remaining items back
  to `critical_major_findings` for the next iteration**. If checker finds issues after `MAX_ITERATIONS`, include them in the final summary as "Unresolved after max iterations".

### 4. Persist Review State

After the loop completes (early-stop or max iterations), write the state file so the next run resumes where this run left off:

```
STATE_FILE = .planning/phases/{PHASE_DIR}/{PHASE}-AGENT-REVIEW-STATE.md
```

Write in this format:

```markdown
# Agent Review State — Phase {PHASE}

## Covered Angles
<!-- Design angles cleanly explored with no open issues. A new run MUST skip these. -->
- {angle_1}
- {angle_2}
...

## Resolved Findings
<!-- Findings that were addressed in plan revisions. -->
- {short description of what was fixed}
...

## Regressions
<!-- Angles re-opened because a later run found new issues after prior run marked them clean. -->
- {angle}: {short description of regression}
...

## Last Run
{ISO date} — {N} iterations, early-stopped: {yes|no}, reviewer-model: {REVIEWER_MODEL}
```

When merging with an existing state file:
- **Merge** `Covered Angles` lists and dedup
- **Regression detection**: if this run found CRITICAL/MAJOR issues in an angle that was previously listed as covered, remove that angle from `Covered Angles` and note it in `## Regressions`

Display:
```
◆ Review state saved → {STATE_FILE}
  Future runs will skip {N} already-covered angles.
```

### 5. Final Summary

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RALPH LOOP COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Iterations completed: N
Early stopped: Yes/No
Reviewer model: {REVIEWER_MODEL}
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
- Running with --reviewer-model opus for deeper analysis
```

---

## Key Differences from codex-plan-ralph-refactor

| Aspect | codex-plan-ralph-refactor | agent-teams-plan-ralph-refactor |
|--------|--------------------------|--------------------------------|
| **Review engine** | Codex CLI (`codex exec`) | Claude Code agent teams (Agent tool) |
| **External deps** | Requires Codex CLI + OpenAI API key | None — all Claude, works out of the box |
| **Session resume** | Codex session resume mechanism | Stateless agents with rich context prompts per iteration |
| **Provider** | `mify` flag for Azure OpenAI proxy | N/A — uses Claude models directly |
| **Model control** | Fixed gpt-5.4 | `--reviewer-model` flag (sonnet/opus) |
| **Code access** | Codex reads files via its sandbox | Agents read files via Read/Grep tools |
| **State file** | `{PHASE}-CODEX-REVIEW-STATE.md` | `{PHASE}-AGENT-REVIEW-STATE.md` |
| **Parallelism** | Codex calls + subagents | Pure agent teams at every stage |

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Phase not found | Error with available phases |
| No PLAN.md files | Suggest /gsd:plan-phase first |
| Reviewer agent fails | Log error, continue with other reviewers' findings |
| Planner fails | Offer retry, skip, or abort |
| Planner returns no file changes | Warn, set stall flag, continue to next iteration |
| Same findings repeat 2 iterations | Abort with "manual review needed" listing stuck findings |
| Reviewer output inconsistent (no-issues string + tags) | Use tag counts, log warning |
| State file unreadable | Warn and start fresh (do not abort) |
| All reviewer agents return empty | Early-stop — plans are clean |

---

## Example Session

```
User: /agent-teams-plan-ralph-refactor 38

Claude:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 AGENT TEAMS PLAN RALPH REFACTOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase: 38
Reviewer Model: sonnet
Max Iterations: 3
Focus: all

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RALPH LOOP — Iteration 1 of 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Reviewer strategy: 3 agents — broad sweep (Contracts+Boundaries, Sequencing+Integration, ErrorStrategy+Observability)
◆ Running parallel reviewer agents...
◆ Dedup: 7 findings → 5 unique
✓ All reviewers complete

◆ Review Findings:
- [CRITICAL] Cross-plan contract broken: Plan 01 and Plan 02 define the shared result type differently — no reconciliation in either plan
- [MAJOR] Missing error strategy: Plan 03 invokes a heavy initialization step but no plan defines what happens if it fails

Issues found: 1 critical, 1 major, 3 minor
Angles covered: Cross-plan contracts, Error recovery strategy, Phase sequencing

◆ Spawning planner...
✓ Planner updated plans
✓ Git diff confirms changes in 2 plan files

◆ Verifying plans...
✓ Verification passed — all findings resolved

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RALPH LOOP — Iteration 2 of 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Reviewer strategy: 1 agent — re-check revised plans + uncovered angles
◆ Running reviewer agent (exploring new angles)...
✓ Review complete

✓ Early stop: No critical or major issues found

◆ Review state saved → .planning/phases/38-.../38-AGENT-REVIEW-STATE.md
  Future runs will skip 4 already-covered angles.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RALPH LOOP COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Iterations completed: 2
Early stopped: Yes
Reviewer model: sonnet

✓ All critical and major issues resolved

Next: /gsd:execute-phase 38
```

### Second run example (new Claude Code window, same phase)

```
User: /agent-teams-plan-ralph-refactor 38

◆ Loaded prior review state: 4 angles already covered from previous run(s)
  Angles: Cross-plan contracts, Error recovery strategy, Phase sequencing, Component ownership

Phase: 38
Reviewer Model: sonnet
Max Iterations: 3
Focus: all

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RALPH LOOP — Iteration 1 of 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Reviewer strategy: 2 agents — exploring uncovered angles (4 pre-covered from prior run)
◆ Running reviewer agents...
✓ Review complete

✓ Early stop: No critical or major design issues found

◆ Review state saved → .planning/phases/38-.../38-AGENT-REVIEW-STATE.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RALPH LOOP COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Iterations completed: 1
Early stopped: Yes — no new design angles remain
Reviewer model: sonnet

Next: /gsd:execute-phase 38
```
