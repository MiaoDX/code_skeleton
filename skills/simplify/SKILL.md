---
name: "simplify"
description: "Review changed code for reuse, quality, and efficiency. Fix any issues found."
metadata:
  short-description: "Review changed code for reuse, quality, and efficiency"
---

<codex_skill_adapter>
## A. Skill Invocation
- This skill is invoked by mentioning `$simplify`.
- Treat all user text after `$simplify` as `{{ARGS}}`.
- If no arguments are present, treat `{{ARGS}}` as empty.

## B. AskUserQuestion → request_user_input Mapping
- `header` → `header`
- `question` → `question`
- Options formatted as `"Label" — description` → `{label: "Label", description: "description"}`
- Generate `id` from header: lowercase, replace spaces with underscores

Batched calls:
- `AskUserQuestion([q1, q2])` → single `request_user_input` with multiple entries in `questions[]`

Multi-select workaround:
- Codex has no `multiSelect`. Use sequential single-selects, or present a numbered freeform list asking the user to enter comma-separated numbers.

Execute mode fallback:
- When `request_user_input` is rejected (Execute mode), present a plain-text numbered list and pick a reasonable default.

## C. Task() → spawn_agent Mapping
- `Task(subagent_type="X", prompt="Y")` → `spawn_agent(agent_type="X", message="Y")`
- `Task(model="...")` → omit (Codex uses per-role config, not inline model selection)
- `fork_context: false` by default — agents load their own context via `<files_to_read>` blocks

Parallel fan-out:
- Spawn multiple agents → collect agent IDs → `wait(ids)` for all to complete

Result parsing:
- Look for structured markers in agent output: `CHECKPOINT`, `SUMMARY`, `FINDINGS`, etc.
- `close_agent(id)` after collecting results from each agent
</codex_skill_adapter>

<objective>
Review all changed files for reuse, quality, and efficiency. Fix any issues found.

Three-phase workflow:
1. Identify changes via `git diff`
2. Launch three review agents in parallel (reuse, quality, efficiency)
3. Aggregate findings and fix each issue directly

Arguments:
- Optional git ref or file path — scope the review (e.g., `$simplify src/auth/` or `$simplify HEAD~3`)
- If no argument, reviews all uncommitted changes
</objective>

<process>

## Phase 1: Identify Changes

Run `git diff` (or `git diff HEAD` if staged changes exist) to see what changed.
If no git changes, review the most recently modified files.

If user provided a scope argument:
- If it looks like a path (contains `/` or `.`), run `git diff -- <path>`
- If it looks like a ref (HEAD~N, commit hash, branch name), run `git diff <ref>...HEAD`
- Otherwise, try path first, then fall back to ref

Extract changed files list and full diff content.

If no changes found, report: "No changes to review." and stop.

## Phase 2: Launch Three Review Agents in Parallel

Spawn all three agents concurrently. Pass each agent the full diff and changed files list.

### Agent 1: Code Reuse Review

Spawn agent with message:

```
You are a Code Reuse Reviewer. Review the following code changes for duplication and missed reuse opportunities.

## Changed Files
{CHANGED_FILES}

## Full Diff
{DIFF_CONTENT}

## Instructions

For each change:
1. Search for existing utilities and helpers that could replace newly written code. Look for similar patterns elsewhere in the codebase — common locations are utility directories, shared modules, and files adjacent to the changed ones.
2. Flag any new function that duplicates existing functionality. Suggest the existing function to use instead.
3. Flag any inline logic that could use an existing utility — hand-rolled string manipulation, manual path handling, custom environment checks, ad-hoc type guards, and similar patterns are common candidates.

For each finding, provide:
- File:Line location
- Description of the duplication/missed reuse
- Suggested existing utility or pattern to use instead

If no reuse issues found, state "NO_REUSE_ISSUES".
```

### Agent 2: Code Quality Review

Spawn agent with message:

```
You are a Code Quality Reviewer. Review the following code changes for hacky patterns and quality issues.

## Changed Files
{CHANGED_FILES}

## Full Diff
{DIFF_CONTENT}

## Instructions

Review for these patterns:
1. Redundant state: state that duplicates existing state, cached values that could be derived, observers/effects that could be direct calls
2. Parameter sprawl: adding new parameters to a function instead of generalizing or restructuring existing ones
3. Copy-paste with slight variation: near-duplicate code blocks that should be unified with a shared abstraction
4. Leaky abstractions: exposing internal details that should be encapsulated, or breaking existing abstraction boundaries
5. Stringly-typed code: using raw strings where constants, enums (string unions), or branded types already exist in the codebase
6. Unnecessary JSX nesting: wrapper Boxes/elements that add no layout value — check if inner component props (flexShrink, alignItems, etc.) already provide the needed behavior
7. Nested conditionals: ternary chains, nested if/else, or nested switch 3+ levels deep — flatten with early returns, guard clauses, a lookup table, or an if/else-if cascade
8. Unnecessary comments: comments explaining WHAT the code does (well-named identifiers already do that), narrating the change, or referencing the task/caller — delete; keep only non-obvious WHY (hidden constraints, subtle invariants, workarounds)

For each finding, provide:
- File:Line location
- Description of the quality issue
- Severity: MUST_FIX | IMPROVE | NITPICK
- Suggested fix

If no quality issues found, state "NO_QUALITY_ISSUES".
```

### Agent 3: Efficiency Review

Spawn agent with message:

```
You are an Efficiency Reviewer. Review the following code changes for performance and efficiency issues.

## Changed Files
{CHANGED_FILES}

## Full Diff
{DIFF_CONTENT}

## Instructions

Review for these patterns:
1. Unnecessary work: redundant computations, repeated file reads, duplicate network/API calls, N+1 patterns
2. Missed concurrency: independent operations run sequentially when they could run in parallel
3. Hot-path bloat: new blocking work added to startup or per-request/per-render hot paths
4. Recurring no-op updates: state/store updates inside polling loops, intervals, or event handlers that fire unconditionally — add a change-detection guard so downstream consumers aren't notified when nothing changed
5. Unnecessary existence checks: pre-checking file/resource existence before operating (TOCTOU anti-pattern) — operate directly and handle the error
6. Memory: unbounded data structures, missing cleanup, event listener leaks
7. Overly broad operations: reading entire files when only a portion is needed, loading all items when filtering for one

For each finding, provide:
- File:Line location
- Description of the efficiency issue
- Severity: MUST_FIX | IMPROVE | NITPICK
- Suggested fix

If no efficiency issues found, state "NO_EFFICIENCY_ISSUES".
```

Wait for all three agents to complete. Collect their outputs.

## Phase 3: Fix Issues

Parse findings from all three agents. For each finding:

1. Read the cited file at the relevant location
2. Evaluate if the finding is valid (not a false positive)
3. If valid, apply a minimal targeted fix
4. If false positive or not worth addressing, note it and move on

Severity handling:
- MUST_FIX: Always fix
- IMPROVE: Fix if it genuinely makes the code better
- NITPICK: Skip unless user explicitly wants all fixes

Fix approach:
- Prefer minimal, local changes
- Do not refactor surrounding code beyond the identified issue
- After fixing, run relevant tests if available

When done, present a brief summary:
- How many issues were found by each reviewer
- How many were fixed
- How many were skipped (with one-line reason for each)
- Any tests run and their results

</process>
