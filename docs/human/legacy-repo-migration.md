# Legacy Repo Migration

Use `$intuitive-migrate` when an older repository needs one coordinated cleanup
loop before future AI-agent work. This is a repository-operational migration:
agent guidance, human docs, layout, tests, and bounded cleanup. It is not a
database/schema migration unless you explicitly add that scope.

## Copy/Paste Prompt

```text
Use $intuitive-migrate for this legacy repo.

Goal: make the repo easier for future AI agents and humans to work in without
changing runtime behavior.

Run the full migration loop:
- create or update one bounded refactor/migration scope gate
- refresh/slim AGENTS.md and CLAUDE.md with $intuitive-init
- audit and update the human doc surface with $intuitive-doc
- audit layout, then apply the highest-value bounded slice with $intuitive-layout
- audit tests, then apply the highest-value cleanup slice with $intuitive-tests

Prefer aggressive cleanup inside accepted scope:
- remove stale compatibility wrappers after in-repo consumers are migrated
- keep README/ARCHITECTURE/STATUS/docs/human as the human truth
- keep planning/evidence/history out of the human surface
- preserve actual behavior unless a change is explicitly accepted

Ask only for decisions that materially change scope, risk, public APIs, deletes,
or external compatibility.
Commit coherent slices along the way.
Run relevant verification after each significant change.
Stop when the accepted checklist is green and remaining ideas are parked.
```

## Expected Outcome

After a successful loop, the repo should have:

- slim project-local `AGENTS.md` and `CLAUDE.md`
- current human docs in `README.md`, `ARCHITECTURE.md`, `STATUS.md`, and
  `docs/human/**`
- one accepted layout slice completed or explicitly parked
- one accepted test cleanup slice completed or explicitly parked
- verification results recorded, with any skipped local-only gates explained
- remaining cleanup ideas parked instead of silently widening the migration
