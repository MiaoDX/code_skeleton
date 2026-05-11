---
name: skill-runner
description: |
  Run a daily development task through one or more named skills in an isolated
  tmux-backed Codex or Claude session. Use when the user asks to "impl X with
  $skill", "run X via $hybrid-phase-pipeline", supervise a skill-driven task,
  keep the main session clean, evaluate the run, or improve custom skills after
  a real task reveals a reusable workflow defect.
---

# Skill Runner

Use this skill to run one real development task in a separate agent session
while the main session stays focused on decisions, review, and synthesis.

The default mindset is daily development, not benchmark tuning. Do not rerun the
same task just to optimize a skill. Learn from varied real tasks, and change a
skill only when a reusable workflow defect is clear.

This skill may repair itself when a real `skill-runner` run reveals a reusable
runner defect, such as false blocker classification, unsafe supervision logic,
or brittle artifact parsing. Keep those patches small and commit them separately
from product-task changes.

## Philosophy

Keep skills small, composable, and boring.

- Prefer principles over long procedures.
- Prefer stop conditions over exhaustive branching.
- Prefer one obvious path over clever options.
- Prefer scripts for deterministic mechanics.
- Prefer references only when optional detail is genuinely needed.
- Prefer deleting or shortening stale guidance over adding more rules.
- Do not encode task-specific lessons as universal rules.
- Do not add a rule unless it prevents a repeated or high-severity failure.
- When a better model can infer it from context, leave it out.

## Default Flow

1. Parse the user task and selected skills.
2. Run `scripts/run_skill_runner.py` with the original prompt.
3. Wait for the tmux session by default, unless the user asks to detach.
4. Read only the compact run artifacts first: `result.md`, `eval.md`, and the
   worker's final message.
5. Inspect the actual diff and verification output before trusting the result.
6. Apply follow-up fixes in the main session only when needed.
7. Consider skill changes only for reusable workflow defects.

Do not paste the whole worker transcript into the main context. Use the run
artifacts and targeted searches through logs.

## Command

From the repo where the task should run:

```bash
python3 /home/mi/ws/code_skeleton/skills/skill-runner/scripts/run_skill_runner.py \
  --agent codex \
  --cwd "$PWD" \
  -- \
  'impl <task> with $hybrid-phase-pipeline then $simplify'
```

Useful options:

- `--agent codex|claude` chooses the worker CLI.
- `--detach` starts tmux and returns immediately.
- `--timeout-min N` caps total runtime.
- `--idle-timeout-min N` stops when logs are quiet too long.
- `--dangerous` lets Codex run without sandbox/approval checks. Use only when
  the surrounding environment is already trusted.
- Known Codex `bwrap` loopback sandbox failures are retried once automatically
  without sandboxing when the worktree status is unchanged. Disable with
  `--no-auto-retry-sandbox-failure`.
- `--dry-run` writes the rewritten prompt and artifacts without starting tmux.

The script writes run artifacts under `~/.cache/skill-runner/runs/` by default.

## Supervisor Mechanics

The runner treats the worker's final `RESULT_STATUS` as authoritative when
`last-message.md` contains one:

- `SUCCESS` maps to a successful run even if the CLI emitted noisy logs.
- `PARTIAL` means useful work landed but follow-up remains.
- `BLOCKED_NEEDS_DECISION` maps to `BLOCKED` even when the CLI exits 0.
- `FAILED` maps to `FAILED` even when the CLI exits 0.

Automatic blocker detection is intentionally narrow. It scans `stderr.log`, not
the whole terminal transcript, so normal repo documentation mentioning auth,
API keys, or setup instructions does not look like a live authentication
failure. Inspect `terminal.log` manually when debugging a run.

## Prompt Rewrite Rules

The worker prompt should be compact and explicit:

- Objective
- Selected skills
- Scope and non-goals
- KISS / Zen constraints
- Source-of-truth rules
- Stop conditions
- Verification required
- Final output shape

For `$hybrid-phase-pipeline`, require coherent phase scope. Do not create many
micro-phases unless the worker first stops and asks for grouping approval.

For `$simplify`, scope review to the actual diff or path. Do not expand into a
broad architecture review.

## Run Evaluation

Classify the run separately from the task result:

- `SUCCESS` - worker completed and evidence supports the claim.
- `PARTIAL` - useful work landed but follow-up is needed.
- `BLOCKED` - worker stopped on a real blocker or needed a decision.
- `FAILED` - worker errored, looped, or made unsafe/unusable changes.

Evaluate behavior using stable invariants that apply across different tasks:

- kept one source of truth
- preserved unrelated changes
- kept scope small
- used named skills honestly
- avoided micro-phase drift
- verified claims with relevant evidence
- stopped or escalated on blockers
- committed only when appropriate
- did not edit custom skills unless explicitly justified

## Skill Change Policy

Default verdict: `NO_SKILL_CHANGE`.

Only patch a skill when the run reveals a reusable workflow defect:

- the skill directly caused bad behavior
- the missing guardrail is general, not task-specific
- the patch can be small
- the patch makes the skill simpler or safer
- the patch is likely to help future varied tasks

Prefer these outcomes, in order:

1. `NO_SKILL_CHANGE`
2. `CANDIDATE_LEARNING` - record, do not edit yet
3. `DELETE_OR_SIMPLIFY`
4. `SMALL_GENERAL_RULE`
5. `MOVE_TO_REFERENCE`
6. `SCRIPT_MECHANIC`

Do not edit third-party or system skills directly. For custom behavior, edit
only custom skills under `/home/mi/ws/code_skeleton/skills`, or wrap external
skills from a custom skill.

Before editing a skill, ask:

- Can this be solved by deleting or shortening stale instructions?
- Can optional detail move to a reference file?
- Can deterministic mechanics move to a script?
- Is this actually a one-off task issue?
- Will this rule still help a stronger model?

After a custom skill change:

```bash
scripts/tasks/sync-local-commands-skills.sh
git add skills scripts/tasks
git commit -m "docs: refine <skill-name> skill"
```

Keep skill refactor commits separate from product-task commits.

## Stop Conditions

Stop or detach for a human decision when:

- the worker asks for approval that cannot be answered safely
- the task needs credentials, paid APIs, local hardware, Docker, or GPU and the
  user did not authorize that gate
- the worker tries to broaden scope beyond the prompt
- more than three phases would be created from one prompt without approval
- the same error repeats
- the worker edits unrelated files
- the worker starts editing skills without a reusable skill-failure rationale

## Final Response

Report:

- tmux session name and run directory
- task result
- verification run
- changed files or commit
- skill-change verdict
- any remaining decision needed
