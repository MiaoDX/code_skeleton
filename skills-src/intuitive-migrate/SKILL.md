---
name: intuitive-migrate
description: |
  Run a bounded legacy-repo migration loop that makes a repository easier for
  humans and AI agents to work in without changing runtime behavior. Use when
  the user asks to migrate, modernize, bootstrap, clean up, or make an old repo
  agent-friendly through intuitive-init, intuitive-doc, intuitive-layout,
  intuitive-tests, and intuitive-refactor together.
---

# Intuitive Migrate

Use this skill to run one coherent legacy-repo cleanup loop. This is a
repository-operational migration: it improves agent guidance, human docs, layout,
tests, and cleanup gates. It does not mean database/schema migrations unless the
user explicitly says so.

The default goal is a repo where future agents can start quickly, humans can
review current truth from a small doc surface, and the next meaningful task does
not require rediscovering stale paths, bloated agent files, or unclear tests.

{{> intuitive-common/human-agent-surface.md}}

{{> intuitive-common/bounded-proposal.md}}

{{> intuitive-common/canonical-cleanup.md}}

## Operating Rule

Start with a bounded migration gate, then run the smallest full loop that can
prove improvement. Prefer aggressive cleanup inside the accepted scope, but do
not turn "make the repo great" into an endless refactor.

Use focused workflows for their strengths:

- `$intuitive-refactor` owns the migration scope gate, accepted severities,
  evidence ladder, parked ideas, and stop condition.
- `$intuitive-init` owns project-local `AGENTS.md` and `CLAUDE.md` refresh or
  slim cleanup.
- `$intuitive-doc` owns the human-facing documentation surface.
- `$intuitive-layout` owns one bounded layout slice at a time.
- `$intuitive-tests` owns one bounded test-suite cleanup slice at a time.

When a focused workflow is available and useful, use it for its evidence and
decision shape instead of duplicating every detail here. If it is unavailable or
would add ceremony without evidence, continue only with a clearly labeled
fallback that preserves the same source-of-truth and stop-condition rules.

## Default Route

Use this route unless the user narrows the migration:

1. **Orient**: read root guidance, human docs, package/test config, automation,
   and top-level layout. Identify current verification commands before edits.
2. **Gate**: run `$intuitive-refactor` to create or update one migration gate,
   normally `docs/plans/refactor-legacy-repo-migration.md` unless a better
   existing plan owns the scope.
3. **Agent guidance**: run `$intuitive-init refresh` or slim cleanup so root
   agent files are local, short, and point at the right human docs and commands.
4. **Human docs**: run `$intuitive-doc audit`, then update missing or drifted
   `README.md`, `ARCHITECTURE.md`, `STATUS.md`, or `docs/human/**` targets.
5. **Layout**: run `$intuitive-layout audit/propose`, then apply the single
   highest-value bounded slice that has clear consumers and verification.
6. **Tests**: run `$intuitive-tests audit/propose`, then apply the single
   highest-value bounded test slice: markers, layout, pruning, fixture/factory,
   or parametrization.
7. **Verify and close**: run the repo's relevant checks, update the migration
   gate status, and park remaining cross-seam ideas.

Run another loop only when the gate still has a concrete P0/P1/P2 item inside
scope. Do not repeat just because more possible cleanup exists.

## Decision Policy

Auto-select a default only when repo evidence makes it low-risk and reversible.
Pause for the user when a decision would materially change:

- runtime behavior or public APIs
- externally documented command/import paths
- broad file moves, deletes, or test pruning
- compatibility shims that may have outside-repo consumers
- paid, slow, Docker, hardware, simulator, or local-provider verification gates
- product intent, audience, or scope

If the user asks for "all feedback questions as needed" or "choose defaults,"
interpret that as permission to choose mechanical defaults, not permission to
cross these pause points silently.

## Aggressive Cleanup Defaults

Inside accepted scope:

- migrate known in-repo consumers to the new canonical docs, paths, commands,
  imports, or test runners
- remove stale wrappers, aliases, duplicate guidance, generated-doc clutter in
  human docs, and low-signal tests once stronger behavior coverage remains
- keep runtime behavior unchanged unless the user explicitly accepts a behavior
  change
- commit coherent verified slices only when the user explicitly asked for
  commits in this run

## Stop Condition

Stop when all of these are true:

- the migration gate is `DONE` or `PARK`, with remaining ideas recorded
- `AGENTS.md` and `CLAUDE.md` are project-local and slim enough to scan, or the
  remaining length is justified by critical startup rules
- the human docs name current setup, architecture, status, and source-of-truth
  boundaries
- at least one accepted layout/test cleanup slice is complete, or those areas
  are audited and explicitly parked as not worth changing now
- verification commands pass, or skipped gates are documented with a concrete
  reason
- the agent can state the next safe task without starting another broad cleanup
  sweep

## Report Format

End with:

```text
Migration gate:
Agent guidance:
Human docs:
Layout slice:
Test slice:
Verification:
Parked items:
Next safe task:
```
