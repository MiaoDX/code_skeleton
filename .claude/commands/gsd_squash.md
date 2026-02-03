---
description: Squash/merge GSD commits to clean up noisy git history
---

Intelligently squash GSD commits into meaningful milestones.

**Goal:** Create a clean git history where each milestone tells a complete story:
- Each GSD phase → one commit (or 2-3 if phase is large)
- Related small phases merged into one milestone
- Contextual grouping for non-phase commits

**Target:** $ARGUMENTS (optional base commit - defaults to merge-base with origin/main or origin/master)

## Milestone Grouping Strategy

**1. Phase-Based Milestones (Primary)**
```
Group commits by phase:
- Phase 1: All commits mentioning "phase-1", "Phase 1:", "[P1]", etc.
- Phase 2: All commits mentioning "phase-2", "Phase 2:", "[P2]", etc.
- Quick Tasks: "quick-NNN", "#NNN:", etc.
```

**2. Phase Merge Logic**
- Small phases (< 3 commits, < 10 files changed) → merge with adjacent phase
- Consecutive phases in same "context" (e.g., setup phases) → group as "Phases 1-3: Setup"
- Large phases (> 10 commits OR > 30 files) → split by type:
  - "Phase N: Core Implementation" (feat, fix, refactor)
  - "Phase N: Documentation & Tests" (docs, test, chore)

**3. Non-Phase Commit Grouping**
- If between phases → merge into nearest phase with same "intent"
- If standalone → group by type prefix (docs, chore, refactor)
- Breaking changes → keep separate with `!` marker

## Workflow

**1. Safety prep**
```bash
# Check for uncommitted changes
UNCOMMITTED=$(git status --porcelain)
if [ -n "$UNCOMMITTED" ]; then
  git stash push -u -m "gsd-squash-temp-$(date +%s)"
  STASHED=1
fi

# Create backup branch
BACKUP_BRANCH="backup-before-squash-$(date +%s)"
git branch "$BACKUP_BRANCH"
echo "Backup created: $BACKUP_BRANCH"
```

**2. Determine base commit**
```bash
if [ -n "$ARGUMENTS" ]; then
  BASE="$ARGUMENTS"
else
  UPSTREAM=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "origin/main")
  BASE=$(git merge-base HEAD "$UPSTREAM")
fi
```

**3. Analyze and group commits**
```bash
# Get all commits with metadata
COMMITS=$(git log --format="%H|%s|%ae|%ad" --date=short --reverse "$BASE..HEAD")

# For each commit, analyze:
# - Phase markers: phase-N, Phase N:, [P N], [Phase N], #NNN (quick tasks)
# - Type prefix: feat:, fix:, docs:, refactor:, chore:, test:
# - Size: git show --stat --format="" $HASH | wc -l
# - Breaking: commit message contains "!" after type or "BREAKING"
```

**4. Build milestone groups**

Algorithm:
```python
milestones = []
current_phase = None
phase_commits = []

for commit in commits:
    phase_num = extract_phase(commit.message)  # e.g., "phase-1" -> 1
    task_num = extract_quick_task(commit.message)  # e.g., "#001" -> 1

    if phase_num:
        # Check if we should merge with previous phase
        if phase_commits and should_merge_phases(current_phase, phase_num, phase_commits):
            phase_commits.append(commit)
        else:
            if phase_commits:
                milestones.append(create_milestone(current_phase, phase_commits))
            current_phase = phase_num
            phase_commits = [commit]
    elif task_num:
        # Quick tasks are standalone or grouped
        milestones.append(create_quick_task_milestone(task_num, commit))
    else:
        # Non-phase commit - check context
        if phase_commits and is_related_to_phase(commit, current_phase):
            phase_commits.append(commit)
        else:
            milestones.append(create_type_milestone(commit))

# Finalize last phase
if phase_commits:
    milestones.append(create_milestone(current_phase, phase_commits))
```

**Merge criteria for small phases:**
```python
def should_merge_phases(prev_phase, curr_phase, prev_commits):
    # Same "decade" (e.g., 1.1, 1.2) or consecutive integers
    same_context = (
        (is_subphase(prev_phase) and is_subphase(curr_phase) and base_phase(prev_phase) == base_phase(curr_phase))
        or (curr_phase == prev_phase + 1 and len(prev_commits) < 3)
    )

    # Size check
    small_phase = len(prev_commits) < 3 and count_files(prev_commits) < 10

    return same_context and small_phase
```

**Split criteria for large phases:**
```python
def should_split_phase(commits):
    return len(commits) > 10 or count_files(commits) > 30

def split_large_phase(phase_num, commits):
    impl_commits = [c for c in commits if c.type in ('feat', 'fix', 'refactor')]
    doc_commits = [c for c in commits if c.type in ('docs', 'test', 'chore')]

    return [
        Milestone(f"Phase {phase_num}: Implementation", impl_commits),
        Milestone(f"Phase {phase_num}: Tests & Docs", doc_commits) if doc_commits else None
    ]
```

**5. Present plan to user**
```
Proposed Milestones:

M1: Phase 1 - Project Setup (3 commits, 8 files)
  └─ feat(phase-1): Initialize project structure
  └─ docs(phase-1): Add README and setup guide
  └─ chore(phase-1): Configure build tools

M2: Phase 2 - Core Implementation (12 commits, 45 files) → SPLIT
  M2a: Phase 2: Implementation (8 commits, 28 files)
    └─ feat(phase-2): Add authentication module
    └─ ...
  M2b: Phase 2: Tests & Docs (4 commits, 17 files)
    └─ test(phase-2): Add auth tests
    └─ ...

M3: Phases 3-4 - API Integration (4 commits, 12 files) [MERGED]
  └─ feat(phase-3): Add HTTP client
  └─ feat(phase-4): Configure API endpoints
  └─ fix(phase-4): Handle rate limiting
  └─ docs(phase-4): API documentation

M4: Quick Task #001 (1 commit)
  └─ fix: Update dependencies

Non-phase commits (3) → merge into nearest phase? [Y/n]
```

**6. Execute squash via interactive rebase**

Generate rebase-todo:
```bash
# Create rebase plan
cat > /tmp/rebase-plan.txt << 'EOF'
# Milestone 1: Phase 1 - Project Setup
pick <hash1> <message1>
fixup <hash2> <message2>
fixup <hash3> <message3>

# Milestone 2a: Phase 2: Implementation
pick <hash4> <message4>
fixup <hash5> <message5>
...

# Milestone 2b: Phase 2: Tests & Docs
pick <hash9> <message9>
fixup <hash10> <message10>
...
EOF

# Execute with GIT_SEQUENCE_EDITOR
GIT_SEQUENCE_EDITOR="cp /tmp/rebase-plan.txt" git rebase -i "$BASE"
```

**7. Rewrite commit messages for milestones**

Each milestone gets a clean commit message:
```
Phase 1: Project Setup

- Initialize project structure
- Add README and setup guide
- Configure build tools

Co-authored-by: Claude <noreply@anthropic.com>
```

For split phases:
```
Phase 2: Core Implementation

- Add authentication module
- Implement user service
- Add JWT token handling

Co-authored-by: Claude <noreply@anthropic.com>
```

**8. Verify integrity**
```bash
# Compare tree objects (code should be identical)
if ! git diff-tree -p "$BACKUP_BRANCH" HEAD | read; then
  echo "Verification passed: history rewritten, code unchanged"
else
  echo "CRITICAL: Code changed during rebase!"
  echo "Restoring backup..."
  git reset --hard "$BACKUP_BRANCH"
  exit 1
fi
```

**9. Cleanup**
```bash
# Restore stashed changes
if [ "$STASHED" = 1 ]; then
  git stash pop
fi

# Show result
echo ""
echo "Squash complete! New history:"
git log --oneline --no-decorate "$BASE..HEAD"

# Check if pushed
if git merge-base --is-ancestor HEAD @{upstream} 2>/dev/null; then
  echo ""
  echo "WARNING: These commits were already pushed. Use force push with caution:"
  echo "  git push --force-with-lease"
fi

echo ""
echo "Backup branch available: $BACKUP_BRANCH"
echo "To restore: git reset --hard $BACKUP_BRANCH"
```

## Error Handling

**Rebase conflicts:**
```bash
# Pause, show status
echo "Rebase conflict detected in files:"
git diff --name-only --diff-filter=U

# Offer choices:
# 1. Resolve manually and continue: git rebase --continue
# 2. Abort and restore: git rebase --abort && git reset --hard "$BACKUP_BRANCH"
```

**Empty commits:**
```bash
# Remove empty commits during rebase
git rebase --continue  # Git will prompt for empty commit handling
```

## Configuration Options

Add to `.planning/config.json`:
```json
{
  "squash": {
    "merge_small_phases": true,
    "small_phase_threshold": {
      "commits": 3,
      "files": 10
    },
    "split_large_phases": true,
    "large_phase_threshold": {
      "commits": 10,
      "files": 30
    },
    "keep_breaking_changes_separate": true
  }
}
```

## Examples

**Example 1: Merge small phases**
```
Before:                    After:
abc phase-1: Init          abc Phase 1: Project Setup
def phase-1: Config        def Phase 2-3: Core Features
ghi phase-2: Small fix     ghi Phase 4: Testing
jkl phase-3: Add test
```

**Example 2: Split large phase**
```
Before (15 commits):       After:
abc phase-5: Feat 1        abc Phase 5: Implementation
...                        def Phase 5: Tests & Docs
opq phase-5: Test 1
```

**Example 3: Non-phase commits**
```
Before:                    After:
abc phase-1: Work          abc Phase 1: Project Setup
def fix: typo    ─────────→ (merged into phase-1)
ghi phase-2: Work          ghi Phase 2: Core Features
jkl docs: update ─────────→ (merged into phase-2)
```
