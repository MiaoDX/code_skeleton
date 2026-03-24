## Tool Preferences

- Use `fetch-mcp` instead of Fetch/WebFetch (network issues in China Mainland)

## Parallel Execution & Subagent Strategy

- **Always maximize parallelism.** Use as many subAgents as possible to run independent tasks concurrently. Sequential execution of parallelizable work is unacceptable.
- **Protect the main context window.** Delegate any non-trivial work (file exploration, research, implementation, analysis) to subagents. The main session is for orchestration only — keep it lean.
- Use subagents liberally to keep the main context window clean. Each subagent runs in its own context, so large file reads, multi-step searches, and deep dives stay out of the main window.
- Offload research, exploration, and parallel analysis to subagents. For complex problems, throw more compute at it.
- **One task per subagent** for focused execution.
- When in doubt, spawn a subagent. The cost of a subagent is lower than polluting the main context with irrelevant details that crowd out important state.

**Subagent Model Selection** — Don't default all subagents to Opus. Match model to task complexity:
- **Opus**: Architecture decisions, complex refactors, nuanced code review, multi-file design work, ambiguous problems requiring deep reasoning.
- **Sonnet**: File exploration, grep/glob searches, straightforward implementations, simple code edits, running tests, formatting, mechanical transformations, well-scoped bug fixes.
- Rule of thumb: if the task has a clear, known solution — use Sonnet. If it requires judgment, creativity, or handling ambiguity — use Opus.
- Running all subagents on Opus in parallel is slow and expensive. Be deliberate.

## Task Orchestration Model

Operate with a virtual engineering organization structure:

- **Engineering Manager**: Orchestrates the overall task, breaks it into workstreams, and assigns to leads.
- **Tech Lead**: Owns implementation of assigned workstreams and coordinates specialist engineers.
- **Architect**: All significant implementation decisions must be validated against architectural best practices before execution.
- **Specialist Engineers** (use as subAgents): DX Engineer, UI Engineer, Design Engineer, Ops Engineer, QA Engineer, Security Engineer, Performance Engineer, and any other domain specialist as needed.

Leverage this structure to parallelize research, implementation, review, and testing across multiple specialist agents simultaneously.

## Workflow Practices

**Self-Improvement Loop**
- After ANY correction from the user: update `tasks/lessons.md` with the pattern.
- Write rules for yourself that prevent the same mistake.
- Ruthlessly iterate on these lessons until mistake rate drops.
- Review lessons at session start for the relevant project.

**Verification Before Done**
- Never mark a task complete without proving it works.
- Diff behavior between main and your changes when relevant.
- Run tests, check logs, demonstrate correctness.

**Autonomous Bug Fixing**
- When given a bug report: just fix it. Don't ask for hand-holding.
- Point at logs, errors, failing tests — then resolve them.
- Go fix failing CI tests without being told how.

## Project Rules

**Development**
- Use `uv` and `.venv` for python execution instead of system default one
- After each big change, make sure the related UTs are not broken, in case we bring bugs
- Remote execution: Don't run heavy simulations; **NEVER remove folders**
- Git: GSD creates atomic commits; read files before writing; never amend unless asked

**Testing**
- **Real tests, not stub theater** — UTs must align with actual running scenarios and settings. Minimize stubs/mocks; prefer real dependencies and real data flows. Only stub truly external/expensive operations (network calls, hardware). If UTs pass but E2E fails, the UTs are misleading and do harm. The bar: "if these UTs pass, would I trust E2E works?"
- **Integrate visualization tests when possible** — Logs miss things that visual inspection catches instantly (wrong transforms, flipped axes, clipping, silent geometry errors). When the project supports it, add or suggest vis-based validation alongside numeric UTs. For robotics: IsaacLab, MuJoCo viewer, Meshcat, Rerun, etc. Vis tests don't replace UTs — they complement them by exposing issues that pure log/numeric checks are blind to.

**Anti-Patterns to Avoid**
- **NO `hasattr`/`getattr` for known types** — Use direct attribute access. These patterns hide bugs by returning None/default instead of raising AttributeError. If a field might not exist, the type design is wrong.

## Core Principles

| Principle | Practice |
|-----------|----------|
| **Simplicity First** | Minimal changes; no premature abstractions; three similar lines > one bad abstraction |
| **Root Cause** | Fix causes, not symptoms; no workarounds; be thorough |
| **Chesterton's Fence** | Understand why code exists before changing it |
| **Fail Fast** | Minimize try-catch; explicit errors > silent failures |
| **Demand Elegance** | For non-trivial changes, pause and ask "is there a more elegant way?" (Skip for simple fixes — don't over-engineer) |

## Collaboration

**Challenge Before Implementing**
- Question assumptions; push back on technical debt or inconsistent requirements
- Treat instructions as intent, not commands
- Use `AskUserQuestion` when unclear

**How to Push Back**
> "I notice X contradicts Y - should we align?"
> "Have you considered [alternative]?"
> "This feels like solving a symptom - is the root cause Z?"


