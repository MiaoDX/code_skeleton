---
description: Squash/merge GSD commits to clean up noisy git history
---

Intelligently squash GSD commits into meaningful, reviewable units.

**Goal:** Clean git history by grouping commits into logical chunks:
- One commit per phase (all phase 1 work, all phase 2 work, etc.)
- Documentation changes grouped together
- Implementation changes grouped together
- Important/breaking changes preserved as standalone commits

**Target:** $ARGUMENTS (optional base commit - defaults to merge-base with origin/main or origin/master)

## Workflow

**1. Safety prep**
- Check for uncommitted changes: `git status --porcelain`
- If found, stash with: `git stash push -u -m "gsd-squash-temp-$(date +%s)"`
- Create backup branch: `git branch backup-before-squash-$(date +%s)`
- Report backup branch name to user

**2. Determine base commit**
```bash
if [ -n "$ARGUMENTS" ]; then
  BASE="$ARGUMENTS"
else
  # Auto-detect merge-base with remote
  UPSTREAM=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "origin/main")
  BASE=$(git merge-base HEAD "$UPSTREAM")
fi
```

**3. Analyze commits**
- Show commits: `git log --oneline --no-decorate $BASE..HEAD`
- Group by pattern analysis:
  - Phase markers: `feat(phase-N)`, `[Phase N]`, `phase N:`, etc.
  - Type prefixes: `docs:`, `feat:`, `fix:`, `refactor:`, etc.
  - Size: count files changed with `git show --stat`
- Present grouping plan with commit counts per group
- Ask user for confirmation via AskUserQuestion

**4. Execute squash**
- Use `git rebase -i $BASE` with auto-generated rebase plan
- First commit in each group: `pick`
- Subsequent commits in group: `squash` (preserves commit messages) or `fixup` (discards messages)
- Large/important commits: keep as `pick`

**5. Verify integrity**
```bash
# Compare tree objects (code should be identical)
git diff-tree -p $BACKUP_BRANCH HEAD

# Should output: nothing (only history changed, not code)
# If diff found: CRITICAL ERROR - restore backup
```

**6. Cleanup**
- Show result: `git log --oneline --no-decorate $BASE..HEAD`
- Restore stashed changes: `git stash pop` (if stashed in step 1)
- Warn if commits were pushed to remote (force push needed)
- Report: backup branch available for rollback if needed

## Error Handling

- **Rebase conflicts:** Pause, show conflict files, offer to abort and restore backup
- **Verification fails:** Auto-restore backup branch, report what changed unexpectedly
- **Stash pop conflicts:** Keep stash, warn user to resolve manually
