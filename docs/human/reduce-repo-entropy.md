# Reduce Repo Entropy

Use `$intuitive-reduce-entropy` when a repository needs periodic maintenance
before future AI-agent work. This is repo-operational cleanup: agent guidance,
human docs, tests, mixed surfaces, stale paths, and bounded cleanup. It is not a
database/schema migration unless you explicitly add that scope.

## Copy/Paste Prompt

```text
Use $intuitive-reduce-entropy for this repo.

Goal: identify the highest-value entropy reduction slice that would make the
repo easier for future AI agents and humans to work in without changing runtime
behavior.

Start by classifying entropy sources:
- agent guidance and harness drift
- human docs and source-of-truth drift
- tests, fixtures, markers, or low-signal coverage
- mixed repo surfaces, scripts, examples, or stale paths
- open-ended architecture/deepening opportunities, shallow modules, or hard-to-test seams
- known stale APIs, wrappers, compatibility shims, or module seams

If one source is clearly highest-value, recommend that slice first.
If not, present 2-4 candidate slices and ask me to choose.

Route to the specialist owner after selection:
- $intuitive-init for AGENTS.md, CLAUDE.md, docs/agents, hooks, MCP, or skills setup
- $intuitive-doc for README, ARCHITECTURE, STATUS, docs/human, or doc-tier drift
- $intuitive-tests for test taxonomy, markers, pruning, fixtures, or test layout
- improve-codebase-architecture for report-only architecture discovery when no target seam is accepted yet
- $intuitive-refactor for known code/module/API cleanup targets or executing an accepted architecture candidate

Prefer aggressive cleanup inside accepted scope:
- remove stale compatibility wrappers after in-repo consumers are migrated
- keep README/ARCHITECTURE/STATUS/docs/human as the human truth
- keep planning/evidence/history out of the human surface
- preserve actual behavior unless a change is explicitly accepted

Ask only for decisions that materially change scope, risk, public APIs, deletes,
or external compatibility.
Commit coherent slices along the way when asked.
Run relevant verification after each significant change.
Stop when the accepted checklist is green and remaining ideas are parked.
```

## Expected Outcome

After a successful maintenance slice, the repo should have:

- one accepted entropy source selected and addressed, or explicitly parked
- current human docs in `README.md`, `ARCHITECTURE.md`, `STATUS.md`, and
  `docs/human/**`
- agent guidance that points at the right docs and commands without bloated
  root files
- test or path cleanup completed only when selected as the highest-value slice
- verification results recorded, with any skipped local-only gates explained
- remaining cleanup ideas parked instead of silently widening the scope
