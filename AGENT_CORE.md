# Gemini Guide

## Environment

- Use `fetch-mcp` instead of Fetch/WebFetch (network issues in China Mainland).
- Use `uv` and `.venv` for Python execution instead of the system interpreter.
- Remote execution: do not run heavy simulations, and never remove folders.

## Delegation And Verification

- Default to parallel delegation for independent, read-heavy, or verification-heavy subtasks.
- Keep the main thread focused on requirements, architecture decisions, integration, and final synthesis.
- Delegate when a task has 2+ independent workstreams, requires reading many files, logs, or test outputs, or when verification can run in parallel with implementation.
- Return summaries to the main thread, not raw notes or long log dumps.
- For concurrent edits, assign disjoint ownership and avoid overlapping write scopes.
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

## Gemini-Specific Notes

- Keep `GEMINI.md` thin and practical. Favor commands, scripts, or reusable workflows over long prompt playbooks.
