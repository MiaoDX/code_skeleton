## Canonical Cleanup Rule

Prefer the new intuitive API, path, module boundary, command shape, or folder
layout over backward compatibility. In an approved cleanup/refactor slice, old
surfaces are migration targets, not contracts.

- Update known in-repo callers, docs, tests, recipes, examples, CI, and command
  references to the new shape.
- Delete old wrappers, aliases, command paths, import paths, dead branches, and
  compatibility shims after known consumers are migrated.
- Keep compatibility only when the user explicitly protects it, a published
  external contract must remain live, or verification shows a non-migratable
  outside-repo consumer.
- If compatibility is kept, mark it temporary and record the removal trigger in
  the active plan, scope gate, or output report.
