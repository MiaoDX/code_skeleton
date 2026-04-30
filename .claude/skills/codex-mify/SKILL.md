---
name: codex-mify
description: Use when the user asks to run Codex CLI through the mify provider. Wraps codex exec/resume with azure_openai/ model prefix required by the mify LiteLLM proxy.
---

# Codex Mify Skill Guide

Wraps the standard Codex CLI invocation to work with the **mify** provider, which requires `azure_openai/` model name prefixes.

## Usage

```
/codex-mify <codex-args...>
```

Arguments are passed through to `codex`, with the model name automatically prefixed with `azure_openai/`.

## How It Works

1. Parse the user's arguments
2. If `-m <model>`, `--model <model>`, or `--model=<model>` is present and the model does NOT already start with `azure_openai/`, prepend `azure_openai/` to the model name
3. Also check for `-c model="..."` config overrides — apply the same prefix rule
4. If no model is specified anywhere, default to `-m azure_openai/gpt-5.5`
5. Run the codex command (no `OPENAI_BASE_URL` override needed — `~/.codex/config.toml` already defines the mify provider with `base_url`)

## Prerequisites

The mify provider must be configured in `~/.codex/config.toml`:

```toml
[model_providers.mify]
name = "mify"
base_url = "http://model.mify.ai.srv/v1"
wire_api = "responses"
```

The API key should be configured via `OPENAI_API_KEY` env var or in the config.

## Model Prefix Rule

| User provides | Sent to mify |
|---------------|-------------|
| (nothing) | `azure_openai/gpt-5.5` |
| `-m gpt-5.5` | `-m azure_openai/gpt-5.5` |
| `-m gpt-5.4-pro` | `-m azure_openai/gpt-5.4-pro` |
| `--model=gpt-5.5` | `--model=azure_openai/gpt-5.5` |
| `-c model="gpt-5.4"` | `-c model="azure_openai/gpt-5.4"` |
| `-m azure_openai/gpt-5.5` | `-m azure_openai/gpt-5.5` (no double prefix) |

## Command Assembly

For `codex exec`:

```bash
codex exec \
  -m azure_openai/{MODEL} \
  {remaining args...}
```

For `codex resume` (supports session ID or `--last`):

```bash
codex resume {SESSION_ID|--last} \
  -m azure_openai/{MODEL} \
  {remaining args...}
```

## Examples

```bash
# Simple exec — auto-prefixes model
/codex-mify exec -m gpt-5.4 --full-auto "Review this code"

# Use pro model for harder tasks
/codex-mify exec -m gpt-5.4-pro --full-auto "Review this code"

# Without model — uses default (gpt-5.4)
/codex-mify exec --full-auto "Analyze auth.py"

# Resume a session
/codex-mify resume abc123 "Continue review"

# Resume latest session
/codex-mify resume --last "Continue from where we left off"

# Explicit azure_openai prefix — no double prefix
/codex-mify exec -m azure_openai/gpt-5.4 --full-auto "Check tests"
```

## Error Handling

| Scenario | Response |
|----------|----------|
| mify endpoint unreachable | Report connection error, suggest checking VPN/network |
| "Not supported model" error | Model not available on mify — known working models include `azure_openai/gpt-5.5`, `azure_openai/gpt-5.4-pro`, `azure_openai/gpt-5.3-codex` (not exhaustive) |
| Codex CLI not found | Suggest `npm i -g @openai/codex` |
