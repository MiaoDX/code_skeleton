@AGENT_CORE.md

## Claude-Specific Notes

- Keep repo-wide constraints in `AGENT_CORE.md`. Keep this file thin.
- Prefer Claude-native imports, slash commands, hooks, skills, and subagents over growing this file into a long workflow manual.
- Use subagents aggressively for independent exploration, review, and verification work, and return concise summaries to the main thread.
- If a workflow must be enforced deterministically, prefer hooks or scripts over prose in this file.

## Docs And Planning

- Keep `README.md` as the thin entry guide and put detailed current-state docs under `docs/`.
- Treat `docs/` as the human docs layer and `.planning/` as the live summary/control-plane layer; do not duplicate full manuals across both.
- Prefer a curated ingest or merge step over broad repo-wide doc discovery when syncing planning from docs.
