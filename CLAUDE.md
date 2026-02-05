# Claude Code Guidelines

> Address me as **MiaoDX** in all responses

## Tool Preferences

- Use `fetch-mcp` instead of Fetch/WebFetch (network issues in China Mainland)

## Core Principles

| Principle | Practice |
|-----------|----------|
| **Simplicity First** | Minimal changes; no premature abstractions; three similar lines > one bad abstraction |
| **Root Cause** | Fix causes, not symptoms; no workarounds; be thorough |
| **Chesterton's Fence** | Understand why code exists before changing it |
| **Fail Fast** | Minimize try-catch; explicit errors > silent failures |

## Collaboration

**Challenge Before Implementing**
- Question assumptions; push back on technical debt or inconsistent requirements
- Treat instructions as intent, not commands
- Use `AskUserQuestion` when unclear

**How to Push Back**
> "I notice X contradicts Y - should we align?"
> "Have you considered [alternative]?"
> "This feels like solving a symptom - is the root cause Z?"

## Project Rules

**Development**
- Use `uv` and `.venv` for python execution instead of system default one
- After each big change, make sure the related UTs are not broken, in case we bring bugs
- Remote execution: Don't run heavy simulations; **NEVER remove folders**
- Git: GSD creates atomic commits; read files before writing; never amend unless asked

**Anti-Patterns to Avoid**
- **NO `hasattr`/`getattr` for known types** — Use direct attribute access. These patterns hide bugs by returning None/default instead of raising AttributeError. If a field might not exist, the type design is wrong.
  ```python
  # BAD: hides typos and missing fields silently
  if hasattr(plan, 'q_grasp') and plan.q_grasp is not None:
  value = getattr(config, 'waist_active', False)

  # GOOD: fails fast on typos, explicit None checks
  if plan.q_grasp is not None:
  value = config.waist_active
  ```

## Pre-Submission Checklist

- [ ] Changes minimal and focused
- [ ] Root cause addressed
- [ ] No unnecessary abstractions
- [ ] Errors fail explicitly and loudly
