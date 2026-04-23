# Codex Guide

## Environment

- Use `fetch-mcp` instead of Fetch/WebFetch (network issues in China Mainland).
- Use `uv` and `.venv` for Python execution instead of the system interpreter.
- Remote execution: do not run heavy simulations, and never remove folders.

## Delegation And Verification

- Default to parallel delegation for independent, read-heavy, or verification-heavy subtasks.
- Keep the main thread focused on requirements, architecture decisions, integration, and final synthesis.
- Delegate when a task has 2+ independent workstreams, requires reading many files, logs, or test outputs, or when verification can run in parallel with implementation.
- Return summaries to the main thread, not raw notes or long log dumps.
- Prefer 2-4 subagents by default. Scale up only for clearly partitioned work.
- Match subagent model strength to task complexity rather than defaulting everything to the highest-cost model.
- This repo often runs through an API relay with a single allowed model; default subagents to the main session model, and only override the model after confirming the target ID is actually available.
- For concurrent edits, assign disjoint ownership and avoid overlapping write scopes.
- Do not wait idly for subagents if non-overlapping local work is available.
- Do not mark work complete without verification. Run relevant tests, inspect logs, or otherwise demonstrate correctness.

## Development And Testing

- Read files before editing. Keep commits atomic. Do not amend unless asked.
- After each significant change, run the related UTs to avoid regressions.
- Prefer real dependencies and realistic data flows over excessive stubs or mocks. Stub only truly external or expensive boundaries.
- Add visualization-oriented validation when the project supports it and numeric or log checks can miss geometry or rendering errors.
- For bug reports and failing CI, start from the failing test or log signal and drive to a verified fix.

## Engineering Style

- Fix root causes rather than papering over symptoms.
- Prefer minimal, local changes over speculative abstraction.
- Understand why existing code exists before changing it.
- Fail fast with explicit errors rather than silent fallbacks.
- Do not use `hasattr()` or `getattr()` for known types. Use direct attribute access.

## Collaboration

- Treat instructions as intent. Flag contradictions, risky assumptions, or technical debt instead of blindly implementing around them.
- Ask a brief clarifying question only when a high-risk ambiguity would materially change the implementation.
- Record repeated repo-specific mistakes in `tasks/lessons.md`.

## Docs And Planning

- Keep `README.md` thin and put detailed current-state setup, runtime, and interface docs under `docs/`.
- Use `docs/` for human-facing truth at `HEAD`, `.planning/` for locked project summaries and execution state, and archive/spec areas for historical design material.
- When a refactor changes runtime truth, update the canonical `docs/` surface in the same slice; if decisions or scope change too, refresh the live `.planning/` summaries as well.

## Codex-Specific Notes

- Keep `AGENTS.md` thin and self-contained. Do not rely on follow-up file reads for critical rules.
- Keep shared repo rules aligned with `AGENT_CORE.md`, but include the operative constraints in this file.
- Move reusable workflows to skills, scripts, or subagents instead of expanding this file.
