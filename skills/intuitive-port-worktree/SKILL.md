---
name: intuitive-port-worktree
description: Port changes from one git worktree or checkout into the default repository folder's current branch. Use when the user asks to move, copy, transfer, transplant, cherry-pick, apply a patch, or port worktree changes into the main/default repo checkout without changing the target branch.
---

# Intuitive Port Worktree

Use this skill to move a change set from a source worktree into the target
default repo checkout while preserving the target checkout's current branch.

The operation name depends on the method:

- **cherry-pick**: replay one or more source commits directly.
- **apply a patch**: apply a diff generated from the source.
- **manual patch port** or **manual cherry-pick**: map the same intent into a
  target branch whose files or APIs have diverged.
- **port changes** or **transplant changes**: generic phrasing for this workflow.

## Operating Rule

Do not switch the target repo to the source branch unless the user explicitly
asks. The target repo's current branch is the destination.

If source and target paths are explicit, execute autonomously. Ask only when the
source payload or target repo is ambiguous enough that the wrong choice would
overwrite unrelated work.

## Discovery

Collect this before editing:

```bash
git -C <source> status --short --branch
git -C <target> status --short --branch
git -C <source> rev-parse --show-toplevel
git -C <target> rev-parse --show-toplevel
git -C <target> worktree list --porcelain
git -C <source> log --oneline --decorate -10
git -C <target> log --oneline --decorate -10
```

Confirm whether the source and target share a git object database:

```bash
git -C <source> rev-parse --path-format=absolute --git-common-dir
git -C <target> rev-parse --path-format=absolute --git-common-dir
```

If they do not share a git common dir, the workflow can still use patches, but
commit refs from the source may not resolve in the target.

## Payload Selection

Prefer the smallest faithful payload:

1. If the user names commit hashes, use those commits.
2. If the source branch has local commits not in target, inspect the range from
   the merge base to source `HEAD`.
3. If the source worktree is dirty, include staged and unstaged diffs only after
   confirming they are intentional from `git status` and `git diff --stat`.
4. If both commits and dirty changes exist, port commits first, then dirty diffs.

Useful inspection commands:

```bash
base=$(git -C <target> merge-base HEAD <source-ref>)
git -C <target> log --oneline --reverse "$base..<source-ref>"
git -C <target> diff --stat "$base..<source-ref>"
git -C <source> diff --stat
git -C <source> diff --cached --stat
```

## Safety Gate

Before modifying the target:

- Read the target status. Do not overwrite unrelated target changes.
- If target is dirty, check whether changed paths overlap the port. If they do,
  stop and ask; otherwise keep the edits separate.
- Create a lightweight backup branch in the target:

```bash
git -C <target> branch backup-before-port-$(date +%Y%m%d-%H%M%S) HEAD
```

Never run destructive cleanup commands. Do not remove remote folders.

## Application Strategy

Choose the least manual method that preserves intent.

### Direct Cherry-Pick

Use when the source commits are clean, relevant as commits, and likely to apply
to the target branch:

```bash
git -C <target> cherry-pick --no-commit <commit-or-range>
```

Use `--no-commit` first so verification can happen before creating a new commit.
If conflicts show the target code has materially diverged, abort and move to
manual patch port:

```bash
git -C <target> cherry-pick --abort
```

### Patch Apply

Use when the source and target share history but a direct cherry-pick is too
broad or the user wants tree changes rather than commit history:

```bash
git -C <target> diff --binary <base>..<source-ref> > /tmp/worktree-port.patch
git -C <target> apply --check --3way /tmp/worktree-port.patch
git -C <target> apply --3way /tmp/worktree-port.patch
```

For dirty source changes:

```bash
git -C <source> diff --binary > /tmp/worktree-port-unstaged.patch
git -C <source> diff --cached --binary > /tmp/worktree-port-staged.patch
git -C <target> apply --check --3way /tmp/worktree-port-staged.patch
git -C <target> apply --3way /tmp/worktree-port-staged.patch
git -C <target> apply --check --3way /tmp/worktree-port-unstaged.patch
git -C <target> apply --3way /tmp/worktree-port-unstaged.patch
```

### Manual Patch Port

Use when paths, APIs, package layout, generated files, or ownership boundaries
changed between source and target.

1. Read the source diff and target canonical files.
2. Map the behavior into the target's current modules and tests.
3. Avoid copying obsolete wrappers or stale paths when the target already has a
   newer canonical location.
4. Keep compatibility shims only if they still exist as target contracts.
5. Preserve user-facing behavior and tests from the source change, not the old
   file layout.

## Verification

After applying changes:

```bash
git -C <target> diff --stat
git -C <target> diff --check
git -C <target> status --short
```

Run the smallest relevant project verification. Prefer repo-native commands
from docs, Makefile, or AGENTS.md. If the target is a Python worktree that uses
`activate.sh`, `uv_run.sh`, or `make`, use those rather than bare `uv run`.

If the source operation had known runtime evidence, rerun or cite the closest
target-side equivalent. Do not mark complete without some verification signal.

## Commit Policy

Commit only when the user asks for a commit, says "as needed", or the repo's
active workflow explicitly requires it.

Use one focused commit in the target. The message should describe the result,
not the transport mechanism, unless the port itself is the point.

## Final Report

Report:

- source path/ref and target path/branch
- method used: cherry-pick, patch apply, or manual patch port
- target commit hash if committed
- main files changed
- verification commands and outcomes
- any residual risk, skipped checks, or source changes intentionally not ported

If the user asks what the operation is called, answer with the precise method
used and the generic name "porting changes between worktrees."
