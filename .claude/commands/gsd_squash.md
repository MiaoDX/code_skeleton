---
description: Squash/merge GSD commits to clean up noisy git history
---

Intelligently squash GSD commits into meaningful milestones to create clean git history.

**Target base commit:** $ARGUMENTS (optional - defaults to merge-base with origin/main or origin/master)

**IMPORTANT HINT:** Make each phase no more than 3 commits, and merge different phases if they are related in concept. Aim for a clean, logical story in the git history.

## Implementation Steps

**1. Safety Preparation**
- Check for uncommitted changes using git status --porcelain
- If uncommitted changes exist, stash them with gsd-squash-temp timestamp
- Create a backup branch named backup-before-squash-TIMESTAMP
- Inform user about the backup branch name

**2. Determine Base Commit**
- If $ARGUMENTS provided, use as base commit
- Otherwise, find upstream branch (git rev-parse --abbrev-ref @{upstream}, default to origin/main)
- Get merge-base between HEAD and upstream

**3. Analyze Commit History**
- Get all commits from base to HEAD with: git log --format="%H|%s|%ae|%ad" --date=short --reverse
- For each commit, identify:
  - Phase markers: phase-N, Phase N:, [P N], [Phase N]
  - Quick task markers: quick-NNN, #NNN
  - Type prefix: feat:, fix:, docs:, refactor:, chore:, test:
  - File changes count: git show --stat --format="" HASH
  - Breaking changes: exclamation mark after type or BREAKING keyword

**4. Group Commits into Milestones**
- GOAL: Each final phase should have no more than 3 commits; merge conceptually related phases together
- Group commits by phase number
- Apply merge logic for small phases (less than 3 commits AND less than 10 files changed)
- Merge consecutive phases in same context (e.g., phases 1.1 and 1.2, or phases 1 and 2 if phase 1 is small)
- Merge phases that are conceptually related even if not consecutive (e.g., "Setup" phases, "Testing" phases)
- Apply split logic for large phases (more than 10 commits OR more than 30 files changed):
  - Split into "Phase N: Implementation" (feat, fix, refactor)
  - Split into "Phase N: Tests & Docs" (docs, test, chore)
- Group quick tasks separately
- Handle non-phase commits by merging into nearest related phase or grouping by type
- Keep breaking changes separate when configured

**5. Present Plan to User**
- Show proposed milestone grouping with commit counts and file counts
- Display commit tree showing which commits go into which milestone
- For splits, show how large phases will be divided
- For merges, show which phases are being combined
- Ask user to confirm before proceeding

**6. Execute Interactive Rebase**
- Generate rebase todo file with pick/fixup commands for each milestone
- First commit in each milestone uses "pick", rest use "fixup"
- Add milestone comments in rebase todo for clarity
- Execute rebase using GIT_SEQUENCE_EDITOR to apply the plan
- Handle rebase conflicts if they occur (pause and inform user)

**7. Rewrite Milestone Commit Messages**
- For each squashed milestone, create clean commit message format:
  - Title: "Phase N: Description"
  - Body: Bullet list of changes from constituent commits
  - Footer: Co-authored-by: Claude <noreply@anthropic.com>
- For merged phases use "Phases N-M: Description"
- For split phases use "Phase N: Part Description"

**8. Verify Integrity**
- Compare tree objects between backup branch and HEAD using git diff-tree
- Ensure code is identical (only history changed)
- If code changed, abort and restore backup with error message

**9. Cleanup and Report**
- Restore stashed changes if any were stashed
- Display new squashed history with git log --oneline
- Show backup branch name and restore instructions
- If commits were already pushed, warn about force push requirements

**10. Error Handling**
- For rebase conflicts: Show conflicting files, offer to resolve or abort
- For empty commits: Let git handle with default behavior
- For any critical errors: Restore backup branch automatically

## Configuration

Thresholds can be customized in .planning/config.json:
- merge_small_phases: true/false
- small_phase_threshold: commits count and files count
- split_large_phases: true/false
- large_phase_threshold: commits count and files count
- keep_breaking_changes_separate: true/false
