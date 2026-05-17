---
name: intuitive-squash
description: Squash local GSD or agent-generated commit history into a clean, reviewable story while preserving important fixes. Use when the user asks to squash commits, clean git history, compress phase commits, prepare a branch before PR, or preserve hotfix/security commits during squash in Claude Code or Codex.
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
6. Present a squash plan and ask for confirmation.
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

Preserved commits stay as standalone `pick` commits. Follow-up fixups that
clearly target a preserved commit may be squashed into that preserved commit,
but not into a milestone group.

## Grouping Heuristics

Aim for at most three final commits per coherent phase.

Group squashable commits by:

- phase markers such as `phase-N`, `Phase N:`, `[P N]`, `[Phase N]`
- issue or quick-task markers
- conventional prefixes such as `feat:`, `fix:`, `docs:`, `test:`,
  `refactor:`, and `chore:`
- changed paths and conceptual intent

Merge tiny related phases. Split very large phases into implementation and
tests/docs commits when that makes review clearer. Keep breaking changes
separate when the commit message or config asks for it.

## Plan Format

Before rewriting, show:

- base ref and commit count
- backup branch name
- proposed final commits, in order
- original commits included in each final commit
- preserved commits with `[PRESERVED]` and the reason
- any dirty-worktree stash that will be restored

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
