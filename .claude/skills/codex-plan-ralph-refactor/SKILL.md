# codex-plan-ralph-refactor

Review GSD phase plans with Codex and auto-refactor using Ralph Loop with early-stop detection.

## Usage

```
/codex-plan-ralph-refactor <phase-number> [mify] [--max-iterations N] [--focus critical|major|all]
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `phase-number` | (required) | Phase to review (e.g., 38) |
| `mify` | (optional) | Use mify provider — auto-prepends `azure_openai/` to model name |
| `--max-iterations` | 3 | Maximum Ralph loop iterations |
| `--focus` | all | Issue severity to focus on |

## Examples

```
/codex-plan-ralph-refactor 38                    # Default: 3 iterations, all issues
/codex-plan-ralph-refactor 38 mify               # Use mify provider
/codex-plan-ralph-refactor 38 --max-iterations 5  # More iterations
/codex-plan-ralph-refactor 38 mify --focus critical # Mify + critical only
```

## When to Use

Use this skill when:
- You have existing GSD phase plans that need review
- You want Codex (gpt-5.4 / gpt-5.4-pro, high reasoning) to find issues (use `mify` arg for mify provider)
- You want automatic plan refactoring via Ralph Loop
- You want early-stop when no critical/major issues remain

---

## Agent Strategy

Maximize parallelism at every stage. The orchestrator (main Claude context) coordinates; specialist agents do the work.

### Agent Roles

| Role | Agent Type | When Used |
|------|-----------|-----------|
| **Codex Reviewer** | Bash (codex CLI) via subagent | Each angle cluster gets its own Codex call |
| **Plan Reviser** | `general-purpose` subagent | Revises plan files to address findings |
| **Plan Checker** | `gsd-plan-checker` subagent | Verifies revised plans meet requirements |

### Parallelization Points

```
Iteration 1 (broad sweep):
├── Codex Review: 2-3 parallel calls, each with different angle cluster
│   ├── Agent A: Safety + Correctness + Error Handling
│   ├── Agent B: Architecture + Coupling + Integration Points
│   └── Agent C: Test Coverage + Edge Cases + Scalability
├── Planner: parallel subagents if multiple PLAN.md files
│   ├── Planner Agent 1: revise PLAN-task-A.md
│   └── Planner Agent 2: revise PLAN-task-B.md
└── Checker: runs after all planners complete

Iteration 2+ (targeted):
├── Single Codex call (resume or new, focused on uncovered angles)
├── Planner: single subagent (targeted revisions)
└── Checker: single subagent
```

### Codex Multi-Angle Strategy (Iteration 1 Only)

On the first iteration, spawn **2-3 parallel subagents** instead of one broad Codex call. Each runs `codex exec` focused on a different angle cluster:

Each subagent runs `codex exec` with the full review prompt (which requires `[CRITICAL]`/`[MAJOR]`/`[MINOR]` tags and `[ANGLE_COVERED: ...]` tags — see Workflow section). Pass the full review prompt to Codex, adding an angle-specific focus line:

```python
# Spawn in parallel — all run concurrently
Agent(
    prompt="Run codex exec with this prompt (use the full structured prompt from the skill, "
           "angle focus: Cross-plan contract consistency — do the plans agree on interfaces "
           "they share? Are component boundaries clearly defined with explicit ownership?)",
    subagent_type="general-purpose",
    description="Codex review: Contracts+Boundaries"
)
Agent(
    prompt="Run codex exec with this prompt (use the full structured prompt from the skill, "
           "angle focus: Phase sequencing and dependencies — can plans execute in declared "
           "wave order? Are there missing prerequisite plans? Are integration points addressed?)",
    subagent_type="general-purpose",
    description="Codex review: Sequencing+Integration"
)
Agent(
    prompt="Run codex exec with this prompt (use the full structured prompt from the skill, "
           "angle focus: Missing error strategies and observability gaps — what happens when "
           "key operations fail? Is there a defined recovery strategy? Can failures be debugged?)",
    subagent_type="general-purpose",
    description="Codex review: ErrorStrategy+Observability"
)
```

**Each agent receives the complete review prompt** (including tag format requirements), not just the angle description. The `{FOCUS_PROMPT_FRAGMENT}` embeds the angle into `{FOCUS_PROMPT}` in the full prompt template.

The orchestrator then deduplicates. Since each agent emits structured `[CRITICAL]`/`[MAJOR]`/`[MINOR]` lines, dedup is a structured merge:

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

**After iteration 1**: Use a single Codex call targeting uncovered angles.

---

## Workflow

### 1. Parse Arguments

Extract from user command:
- `PHASE`: Phase number (required)
- `PROVIDER`: If the word `mify` appears as a positional arg, set `PROVIDER = "mify"`. Default: `"default"`
- `MAX_ITERATIONS`: Default 3, override with `--max-iterations N`
- `FOCUS`: Default "all", choices: critical, major, all

#### Resolve Model Name

```python
BASE_MODEL = "gpt-5.4"

if PROVIDER == "mify":
    CODEX_MODEL = f"azure_openai/{BASE_MODEL}"
else:
    CODEX_MODEL = BASE_MODEL
```

All `codex exec` and `codex resume` commands below use `{CODEX_MODEL}` instead of the hardcoded model name. No `OPENAI_BASE_URL` override is needed — `~/.codex/config.toml` already defines the mify provider with its `base_url`.

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
STATE_FILE = .planning/phases/{PHASE_DIR}/{PHASE}-CODEX-REVIEW-STATE.md
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
CODEX_SESSION_ID = None         # Session ID for resume capability
PREV_ITER_FINGERPRINTS = set()  # Normalized finding descriptions from last iter (stall detection)
STALL_COUNT = 0                 # Consecutive iterations with identical findings
```

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CODEX PLAN RALPH REFACTOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase: {PHASE}
Provider: {PROVIDER} (model: {CODEX_MODEL})
Max Iterations: {MAX_ITERATIONS}
Focus: {FOCUS}
```

For each iteration:

#### A. Run Codex Review (Auto-Choose Resume vs New, Multi-Angle on Iter 1)

**Iteration 1: Multi-angle parallel review** (see Agent Strategy above).
Spawn 2-3 parallel subagents, each running `codex exec` with a focused angle cluster. Merge all findings before proceeding to early-stop check.

**Iteration 2+: Single Codex call** with session mode auto-selection.

Apply rules **in priority order** (first match wins):

| Priority | Condition | Mode | Rationale |
|----------|-----------|------|-----------|
| 1 | Every 3rd iteration (iter % 3 == 0) | `exec` (new) | Diversity injection overrides everything |
| 2 | Previous iter found only MINOR or nothing | `exec` (new) | Stalling — fresh perspective |
| 3 | Previous iter revised plans (`PREV_HAD_FIXES`) | `resume` | Codex needs context of what changed |
| 4 | Default | `exec` (new) | No reason to resume |

Display the choice:
```
◆ Session mode: {resume|new} — {reason}
```

**Build the review prompt** with angle expansion (after iteration 1):

```
You are reviewing GSD phase PLAN files in .planning/phases/{PHASE}-*/.

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

{ANGLE_EXPANSION_BLOCK if COVERED_ANGLES is non-empty}
```

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

**If using `exec` (new session)**:

```bash
codex exec --skip-git-repo-check \
  -m {CODEX_MODEL} \
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
  -m {CODEX_MODEL} \
  --config model_reasoning_effort="high" \
  --sandbox read-only \
  --full-auto \
  -C $(pwd) \
  "<REVIEW_PROMPT>"
```

If `resume` fails (session expired, etc.), fall back to `exec` once. If `exec` also fails,
abort the iteration with:
```
✗ Codex unavailable after 2 attempts. Retry later or run /codex-plan-ralph-refactor {PHASE} again.
```
Do not silently loop — report the failure and stop.

FOCUS_PROMPT mapping:
- `critical`: "Look only for CRITICAL design blockers: contradictory contracts between plans, impossible phase sequencing, missing dependencies that make the design unimplementable"
- `major`: "Look for CRITICAL and MAJOR design gaps: missing error recovery strategies, cross-plan interface inconsistencies, unclear component ownership of shared state, integration points not addressed"
- `all`: "Look for all design concerns — component boundaries, cross-plan contracts, error strategies, phase dependencies, test coverage strategy, and observability gaps"

#### B. Check Early-Stop & Track Angles

Parse Codex output — **tag counts are authoritative and override summary strings**:

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
     log `⚠ Codex output inconsistent: claimed no issues but flagged N finding(s). Using tag counts.`

Update session state:
```python
PREV_HAD_FIXES = False  # updated after step D (git diff check)
```

Note: stall detection runs **after** step D (git diff), not here — see step D.

Display findings:
```
◆ Codex Findings:
- [CRITICAL] ...
- [MAJOR] ...

Issues found: X critical, Y major, Z minor
```

#### C. Spawn Planner(s) (if issues remain)

**Route findings to plan files first** — extract a `file → [findings]` mapping before spawning planners:

```python
# Each finding mentions affected plan files in its description.
# Build routing map: {plan_file: [finding, ...]}
# If a finding affects multiple files, include it in each file's list.
# If a finding cannot be mapped to a specific file, include in all files that could be relevant.
FILE_FINDINGS = defaultdict(list)
for finding in critical_major_findings:
    for plan_file in extract_affected_files(finding):  # parse file refs from finding text
        FILE_FINDINGS[plan_file].append(finding)
```

**If multiple plan files have findings** — spawn parallel planner subagents:

```python
Agent(
    prompt=f"Revise {plan_file} to address these findings:\n\n" +
           "\n".join(FILE_FINDINGS[plan_file]),
    subagent_type="general-purpose",
    description=f"Revise {plan_file}"
)
# ... one per file with findings
```

**If phase has a single PLAN.md** — spawn one planner subagent:

```python
Agent(
    prompt="Revise Phase {PHASE} plans to address Codex findings:\n\n{CODEX_OUTPUT}",
    subagent_type="general-purpose",
    description=f"Revise Phase {PHASE} plans"
)
```

Each planner should:
1. Read its assigned PLAN.md file(s)
2. Update plans to address findings (CRITICAL first, then MAJOR)
3. Make structural design changes — close the actual gap, don't just add an explanatory note.
   Examples of structural fixes:
   - Missing cross-plan contract: add an explicit `<interfaces>` section or update `must_haves` to align both sides
   - Missing error strategy: add a decision (e.g. "on planner timeout: skip position and log SKIP") not just "consider error handling"
   - Ambiguous component ownership: explicitly name the owner in the relevant task description
   If pseudocode is genuinely misleading (e.g. uses a wrong string literal that could confuse the executor), correct the pseudocode — but do NOT add boilerplate notes defending every pseudocode detail
4. **Anti-regression rule**: Do NOT remove existing design constraints, interface definitions, or error strategies to resolve a finding. If two plans conflict, reconcile by aligning both sides — never by deleting from one. Removing a constraint is not a fix; it's hiding the problem.
5. Return:
   ```
   ## PLANNING COMPLETE

   ## Changes Made
   - {plan_file}: {what was added/modified} — addresses finding: {finding short description}
   - ...
   ```
   The `## Changes Made` section is required. The orchestrator uses it to verify actual work was done.

#### D. Verify Planner Changes + Stall Detection

Confirm the planner made real changes:

```bash
git diff --name-only -- '.planning/phases/{PHASE_DIR}/'
```

- If diff is **non-empty**: set `PREV_HAD_FIXES = True`
- If diff is **empty**: set `PREV_HAD_FIXES = False`, log `⚠ Planner claimed completion but no plan files changed.`

**Then run stall detection** (after knowing whether planner actually changed anything):

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
    description=f"Verify Phase {PHASE} plans"
)
```

Checker should return:
- "## VERIFICATION PASSED" with per-finding RESOLVED confirmations → **continue to next iteration**
- "## ISSUES FOUND" with structured list of what's still missing → **add remaining items back
  to `critical_major_findings` for the next iteration** (do not count as a new Codex iteration;
  these are carry-forwards). If checker finds issues after `MAX_ITERATIONS`, include them in the
  final summary as "Unresolved after max iterations".

### 4. Persist Review State

After the loop completes (early-stop or max iterations), write the state file so the next run (even in a fresh context) resumes where this run left off:

```
STATE_FILE = .planning/phases/{PHASE_DIR}/{PHASE}-CODEX-REVIEW-STATE.md
```

Write in this format:

```markdown
# Codex Review State — Phase {PHASE}

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
{ISO date} — {N} iterations, early-stopped: {yes|no}
```

When merging with an existing state file:
- **Merge** `Covered Angles` lists and dedup
- **Regression detection**: if this run found CRITICAL/MAJOR issues in an angle that was previously listed as covered, remove that angle from `Covered Angles` and note it in `## Regressions`:
  ```markdown
  ## Regressions
  <!-- Angles re-opened because new issues were found after prior run marked them clean -->
  - {angle}: {short description of new finding}
  ```
  This prevents a stale "covered" status from masking real regressions on future runs.

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
| Codex resume fails + exec fails | Abort iteration with clear message, suggest retry |
| Planner fails | Offer retry, skip, or abort |
| Planner returns no file changes | Warn, set stall flag, continue to next iteration |
| Same findings repeat 2 iterations | Abort with "manual review needed" listing stuck findings |
| Codex output inconsistent (no-issues string + tags) | Use tag counts, log warning |
| State file unreadable | Warn and start fresh (do not abort) |

---

## Example Session

```
User: /codex-plan-ralph-refactor 38

Claude:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CODEX PLAN RALPH REFACTOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase: 38
Provider: default (model: gpt-5.4)
Max Iterations: 3
Focus: all

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RALPH LOOP — Iteration 1 of 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Session mode: new — first iteration
◆ Running Codex review...
✓ Codex review complete

◆ Codex Findings:
- [CRITICAL] Cross-plan contract broken: Plan 01 and Plan 02 define the shared result type differently — no reconciliation in either plan
- [MAJOR] Missing error strategy: Plan 03 invokes a heavy initialization step but no plan defines what happens if it fails

Issues found: 1 critical, 1 major, 0 minor
Angles covered: Cross-plan contracts, Error recovery strategy

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

◆ Review state saved → .planning/phases/38-.../38-CODEX-REVIEW-STATE.md
  Future runs will skip 3 already-covered angles.

Next: /gsd:execute-phase 38
```

### Second run example (new Claude Code window, same phase)

```
User: /codex-plan-ralph-refactor 38

◆ Loaded prior review state: 3 angles already covered from previous run(s)
  Angles: Cross-plan contracts, Error recovery strategy, Phase sequencing

Phase: 38
Provider: default (model: gpt-5.4)
Max Iterations: 3
Focus: all

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RALPH LOOP — Iteration 1 of 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

◆ Session mode: new
◆ Running Codex review (3 angles pre-covered from prior run)...
✓ Codex review complete

✓ Early stop: No critical or major design issues found

◆ Review state saved → .planning/phases/38-.../38-CODEX-REVIEW-STATE.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RALPH LOOP COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Iterations completed: 1
Early stopped: Yes — no new design angles remain

Next: /gsd:execute-phase 38
```
