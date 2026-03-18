---
description: Squash GSD commits into clean history while preserving important bug fixes
---

Intelligently squash GSD commits into meaningful milestones to create clean git history while preserving important bug fixes as standalone commits.

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
  - **Preserve markers** (see Step 3b)

**3b. Identify Commits to Preserve**

Some commits must NOT be squashed — they stay as standalone commits in the final history. Detect these by:

- **Keyword markers in commit message** (case-insensitive):
  - `hotfix:`, `critical:`, `security:` type prefixes
  - `IMPORTANT`, `CRITICAL`, `SECURITY`, `CVE-` anywhere in subject
  - `DO NOT SQUASH`, `PRESERVE`, `KEEP` directives in subject or body
- **Fix commits that reference issues/tickets**: `fix: #123`, `fixes PROJ-456`, `closes #789`
- **Commits that touch safety-critical paths** (configurable in .planning/config.json under `preserve_paths`):
  - e.g., `auth/`, `security/`, `migrations/`, `*.lock`
- **Commits by external contributors** (author email differs from the primary committer)

For each detected commit, read its full message with `git log -1 --format="%B" HASH` to check the body for preserve directives too.

Tag each commit as either `squashable` or `preserve`. The preserve tag propagates: if a later commit is a direct follow-up fix to a preserved commit (detected by "fixup for HASH" or amending the same files), it gets squashed INTO the preserved commit, not into the milestone.

**4. Group Commits into Milestones**
- GOAL: Each final phase should have no more than 3 commits; merge conceptually related phases together
- **Preserved commits are never absorbed into milestone squashes** — they remain as individual picks
- Group remaining squashable commits by phase number
- Apply merge logic for small phases (less than 3 commits AND less than 10 files changed)
- Merge consecutive phases in same context (e.g., phases 1.1 and 1.2, or phases 1 and 2 if phase 1 is small)
- Merge phases that are conceptually related even if not consecutive (e.g., "Setup" phases, "Testing" phases)
- Apply split logic for large phases (more than 10 commits OR more than 30 files changed):
  - Split into "Phase N: Implementation" (feat, fix, refactor)
  - Split into "Phase N: Tests & Docs" (docs, test, chore)
- Group quick tasks separately
- Handle non-phase commits by merging into nearest related phase or grouping by type
- Keep breaking changes separate when configured
- Insert preserved commits in chronological position between milestone groups

**5. Present Plan to User**
- Show proposed milestone grouping with commit counts and file counts
- **Clearly mark preserved commits with a [PRESERVED] tag and show the reason** (e.g., "hotfix keyword", "references #123", "touches auth/")
- Display commit tree showing which commits go into which milestone
- For splits, show how large phases will be divided
- For merges, show which phases are being combined
- **Ask the user**: "Any other commits you want to preserve or squash?" — allow manual override before proceeding
- Ask user to confirm before proceeding

**6. Execute Interactive Rebase**
- Generate rebase todo file with pick/fixup commands for each milestone
- First commit in each milestone uses "pick", rest use "fixup"
- **Preserved commits always use "pick"** — never "fixup" or "squash"
- **Follow-up fixes to preserved commits use "fixup"** immediately after their parent preserved commit
- Add milestone comments in rebase todo for clarity
- Add `# PRESERVED: <reason>` comments for preserved commits
- Execute rebase using GIT_SEQUENCE_EDITOR to apply the plan
- Handle rebase conflicts if they occur (pause and inform user)

**7. Rewrite Milestone Commit Messages**
- For each squashed milestone, create clean commit message format:
  - Title: "Phase N: Description"
  - Body: Bullet list of changes from constituent commits
  - Footer: Co-authored-by: Claude <noreply@anthropic.com>
- For merged phases use "Phases N-M: Description"
- For split phases use "Phase N: Part Description"
- **For preserved commits**: keep the original commit message intact, only append Co-authored-by if missing. Do NOT rewrite the subject line — the original wording is intentional.

**8. Verify Integrity**
- Compare tree objects between backup branch and HEAD using git diff-tree
- Ensure code is identical (only history changed)
- **Verify preserved commits exist in the final history** by checking their subject lines appear in `git log --oneline`
- If code changed, abort and restore backup with error message
- If any preserved commit is missing from final history, abort and restore backup

**9. Cleanup and Report**
- Restore stashed changes if any were stashed
- Display new squashed history with git log --oneline
- **Highlight preserved commits in the output** (prefix with "* " or similar marker)
- Show backup branch name and restore instructions
- If commits were already pushed, warn about force push requirements

**10. Error Handling**
- For rebase conflicts: Show conflicting files, offer to resolve or abort
- For empty commits: Let git handle with default behavior
- For any critical errors: Restore backup branch automatically
- **If a preserved commit causes a conflict during rebase**: prioritize resolving it over aborting — these commits are important by definition

## Configuration

Thresholds can be customized in .planning/config.json:
- merge_small_phases: true/false
- small_phase_threshold: commits count and files count
- split_large_phases: true/false
- large_phase_threshold: commits count and files count
- keep_breaking_changes_separate: true/false
- preserve_paths: list of glob patterns for safety-critical paths (e.g., ["auth/**", "migrations/**", "*.lock", "security/**"])
- preserve_keywords: additional keywords that mark a commit as preserved (beyond the built-in list)
