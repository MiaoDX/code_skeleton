---
description: Use Zen to consult Gemini and Codex for double-checking or planning
---

Use the Zen MCP server to get a second opinion on the current task or plan.

Steps:
1. Use zen talk to send the context/question to `gemini-3-pro-preview-pt` model (not the cli or clink)
2. Use zen talk to send the context/question to `codex` model (not the cli or clink)
3. Summarize the key feedback from both models
4. Highlight any disagreements or important insights

Context to check: $ARGUMENTS
