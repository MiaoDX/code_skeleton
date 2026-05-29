---
name: intuitive-squash
description: Squash local GSD or agent-generated commit history into a clean, reviewable story while preserving important fixes. Use when the user asks to squash commits, clean git history, compress phase commits, prepare a branch before PR, compare aggressive vs moderate squash options, or preserve hotfix/security commits during squash in Claude Code or Codex.
---

# Intuitive Squash

Use this skill to turn noisy local agent history into a small set of meaningful
commits without changing the final tree.

This is a history-rewrite workflow. Do not proceed past the proposed plan until
the user explicitly confirms it.

## Inputs

- Optional base ref from the user.
- If no base is provided, use the merge base with the upstream branch, falling
  back to `origin/main` or `origin/master`.
- Treat the current branch only as the rewrite target.

## Safety Protocol

1. Check `git status --porcelain`.
2. If the worktree is dirty, stash it with a timestamped name such as
   `intuitive-squash-temp-YYYYMMDD-HHMMSS`.
3. Create a backup branch before rewriting:
   `backup-before-intuitive-squash-YYYYMMDD-HHMMSS`.
4. Tell the user the backup branch name.
5. Analyze commits from base to `HEAD` in chronological order.
6. Present squash plan options and ask for confirmation.
7. Only after confirmation, run the history rewrite.
8. Verify the final tree matches the backup branch.
9. Restore any temporary stash.

If verification fails, stop and restore from the backup branch.

## Preserve Rules

Never squash these commits into a generic milestone:

- Subjects or bodies containing `DO NOT SQUASH`, `PRESERVE`, `KEEP`,
  `IMPORTANT`, `CRITICAL`, `SECURITY`, or `CVE-`.
- Type prefixes such as `hotfix:`, `critical:`, or `security:`.
- Fix commits that reference issues or tickets, such as `fix: #123`,
  `fixes PROJ-456`, or `closes #789`.
- Commits touching safety-critical paths from `.planning/config.json`
  `preserve_paths`, when present.
- Commits from an external author relative to the main local committer.

Preserved commits stay as standalone `pick` commits in every proposed plan.
Follow-up fixups that clearly target a preserved commit may be squashed into
that preserved commit, but not into a milestone group.

## Plan Options

Default to two proposed plans unless the user asks for one exact strategy:

- **Aggressive**: compress the branch into the fewest reviewable commits. This
  is useful for agent noise, but it must still keep preserved commits separate
  and avoid mixing unrelated runtime, docs, tests, and dependency changes into
  a vague mega-commit.
- **Moderate**: keep semantic review boundaries while still removing fixup and
  phase-churn noise. This should usually be the recommended plan for large or
  high-risk branches, especially when the history spans multiple subsystems,
  runtime behavior, tests, docs, or dependency changes.

For small stacks, the two plans may differ only slightly. Say that explicitly
instead of inventing artificial splits.

For large stacks, a moderate plan often lands around 12-18 commits. Treat that
as a reviewability target, not a hard rule: use fewer commits for a narrow
feature and more only when the branch genuinely has independent semantic
surfaces.

## Grouping Heuristics

Build commits that a reviewer can understand, test, and revert as a coherent
unit. Prefer semantic commits over purely date-based, phase-number-based, or
prefix-based grouping.

Group squashable commits by:

- phase markers such as `phase-N`, `Phase N:`, `[P N]`, `[Phase N]`
- issue or quick-task markers
- conventional prefixes such as `feat:`, `fix:`, `docs:`, `test:`,
  `refactor:`, and `chore:`
- changed paths and conceptual intent

Separate commits when they represent different review or rollback surfaces:

- dependency or environment changes
- public API or contract changes
- runtime behavior changes
- tests, harnesses, and validation gates
- documentation-only truth updates
- mechanical moves or renames
- experimental probes versus promoted production behavior

Merge tiny related phases. Split very large phases into implementation and
tests/docs commits when that makes review clearer. Keep breaking changes
separate when the commit message or config asks for it.

Avoid over-aggressive groups with generic names such as `feat: update project`
or `refactor: cleanup`. If a proposed commit needs several unrelated clauses in
the subject to explain itself, split it in the moderate plan.

## Plan Format

Before rewriting, show:

- base ref and commit count
- backup branch name
- proposed final commits, in order, for both `Aggressive` and `Moderate`
- original commits included in each final commit
- preserved commits with `[PRESERVED]` and the reason
- any dirty-worktree stash that will be restored
- recommended option and why

Ask: `Any other commits you want to preserve or squash?`

## Rewrite And Verify

Use interactive rebase or another git-native rewrite mechanism. Preserved
commits must remain `pick`. Squashed milestone commit messages should be clean
and human-readable, with a concise body describing the included changes.

After the rewrite:

```bash
git diff --exit-code backup-before-intuitive-squash-YYYYMMDD-HHMMSS..HEAD
git diff-tree --quiet backup-before-intuitive-squash-YYYYMMDD-HHMMSS HEAD
```

Also verify preserved commit subjects still appear in `git log --oneline`.

Report the new history, the backup branch, any restored stash, and whether a
force push is needed.
