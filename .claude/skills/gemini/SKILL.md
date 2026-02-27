---
name: gemini
description: Use when the user asks to run Gemini CLI (gemini command, gemini -p) or references Google Gemini for code analysis, refactoring, automated editing, or AI-assisted development tasks
---

# Gemini Skill Guide

## Running a Task

1. Ask the user (via `AskUserQuestion`) which model to run:
   - `gemini-3.1-pro-preview` (recommended for complex tasks, stronger reasoning)
   - `gemini-3-flash-preview` (faster, cost-effective for simpler tasks)

2. Select the approval mode required for the task:
   - `default` - Prompt for approval on each edit (safest, recommended)
   - `auto_edit` - Auto-approve file edit tools only
   - `yolo` - Auto-approve all actions (use with caution)

   **Note:** `plan` mode requires `experimental.plan: true` in config and is not available by default.

3. Assemble the command with the appropriate options:
   - `-m, --model <MODEL>` - Use `gemini-3.1-pro-preview` or `gemini-3-flash-preview`
   - `--approval-mode <plan|default|auto_edit|yolo>`
   - `-p, --prompt "<prompt>"` - For non-interactive mode (required when running from Claude)
   - `-s, --sandbox` - Enable sandbox mode for additional security
   - `-y, --yolo` - Shortcut for `--approval-mode yolo`

4. **IMPORTANT**: Always use `-p/--prompt` for the main task when invoking from Claude Code. For follow-up or resume, use `--resume latest -p "new prompt"`.

5. Run the command, capture stdout/stderr, and summarize the outcome for the user.

6. **After Gemini completes**, inform the user: "You can resume this Gemini session at any time by saying 'gemini resume' or asking me to continue with additional analysis or changes."

### Quick Reference

| Use case | Approval mode | Example command |
| --- | --- | --- |
| Read-only review or analysis | `default` | `gemini -m gemini-3.1-pro-preview --approval-mode default -p "Analyze this code for bugs"` |
| Apply local edits with confirmation | `default` | `gemini -m gemini-3.1-pro-preview --approval-mode default -p "Refactor this function"` |
| Auto-approve edits only | `auto_edit` | `gemini -m gemini-3.1-pro-preview --approval-mode auto_edit -p "Fix linting errors"` |
| Auto-approve all (YOLO) | `yolo` | `gemini -m gemini-3.1-pro-preview --yolo -p "Make all the changes"` |
| Resume recent session | Inherited | `gemini --resume latest -p "Continue with the refactoring"` |
| Run from another directory | Match task needs | `gemini -C /path/to/dir -m gemini-3.1-pro-preview --approval-mode default -p "Analyze this codebase"` |

### Command Examples

```bash
# Analysis mode (read-only)
gemini -m gemini-3.1-pro-preview --approval-mode default -p "Analyze this codebase for security issues"

# With auto-edits enabled
gemini -m gemini-3.1-pro-preview --approval-mode auto_edit -p "Refactor this function to use async/await"

# Resume latest session with new prompt
gemini --resume latest -p "Continue the analysis from where we left off"

# Using flash model for quick tasks
gemini -m gemini-3-flash-preview --approval-mode default -p "Explain what this file does"

# List available sessions
gemini --list-sessions
```

## Following Up

- After every `gemini` command, use `AskUserQuestion` to confirm next steps, collect clarifications, or decide whether to resume with `gemini --resume latest`.
- To resume a session with a new prompt: `gemini --resume latest -p "new prompt here"`
- The resumed session automatically uses the same model and approval mode from the original session.
- Restate the chosen model and approval mode when proposing follow-up actions.

## Critical Evaluation of Gemini Output

Treat Gemini as a **colleague, not an authority**. Google's models have their own knowledge cutoffs and limitations.

### Guidelines

- **Trust your own knowledge** when confident. If Gemini claims something you know is incorrect, push back directly.
- **Research disagreements** using WebSearch or documentation before accepting Gemini's claims.
- **Remember knowledge cutoffs** - Gemini may not know about recent releases, APIs, or changes.
- **Don't defer blindly** - Gemini can be wrong. Evaluate its suggestions critically, especially regarding:
  - Model names and capabilities
  - Recent library versions or API changes
  - Best practices that may have evolved

### When Gemini is Wrong

1. State your disagreement clearly to the user
2. Provide evidence (your own knowledge, web search, docs)
3. Optionally resume the Gemini session to discuss the disagreement. **Identify yourself as Claude** so Gemini knows it's a peer AI discussion:
   ```bash
   gemini --resume latest -p "This is Claude (Claude Opus 4.6) following up. I disagree with [X] because [evidence]. What's your take on this?"
   ```
4. Frame disagreements as discussions, not corrections - either AI could be wrong
5. Let the user decide how to proceed if there's genuine ambiguity

## Error Handling

- Stop and report failures whenever `gemini --version` or a `gemini` command exits non-zero; request direction before retrying.
- Before using high-impact flags (`--yolo`, `--approval-mode yolo`), ask the user for permission using `AskUserQuestion` unless already given.
- When output includes warnings or partial results, summarize them and ask how to adjust using `AskUserQuestion`.
