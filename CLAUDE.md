# Claude Code Guidelines

> Address me as **MiaoDX** in all responses

## Core Principles

**Simplicity First**
- Keep changes minimal - impact only necessary code
- Avoid over-engineering, premature abstractions, or "improvements" beyond the ask
- Three similar lines > one premature abstraction

**Root Cause Analysis**
- Find and fix the root cause, not symptoms
- No temporary fixes or workarounds
- Act as a senior developer - thorough, not lazy

**Fail Fast & Explicit**
- Minimize try-catch blocks - let errors surface early
- Explicit failures > silent fake-success
- Follow Zen of Python principles

## Modern Workflow Integration

**Task Management**
- Use `TaskCreate`/`TaskUpdate` for complex multi-step work
- Mark tasks `in_progress` when starting, `completed` when done
- For simple tasks, skip task tracking and just do the work

**Built-in Workflows**
- `/explore` - Understand codebase structure
- `/build` - Plan and implement features
- `/fix` - Debug and resolve issues
- `/commit` - Create git commits (no Claude attribution)
- `/recall` - Query past session learnings

**Plan Before Code**
- Use `EnterPlanMode` for non-trivial implementation
- Research first (read files, explore patterns)
- Get plan approval before coding
- Iterate on plan based on feedback

## Agent Delegation

**Keep Main Context Clean**
- Delegate exploration → `scout` agent
- Delegate research → `oracle` agent
- Delegate implementation → `kraken` or `spark` agent
- Delegate testing → `arbiter` agent

**When to Delegate**
- Reading 3+ files
- External documentation research
- Complex multi-file changes
- Running test suites

**Main Context For**
- Understanding user intent
- Coordinating agents
- Making architectural decisions
- Presenting summaries

## Memory System

**Before Starting Work**
```bash
# Check if we've solved similar problems
(cd $CLAUDE_OPC_DIR && uv run python scripts/core/recall_learnings.py --query "topic" --k 3 --text-only)
```

**After Solving Tricky Problems**
```bash
# Store learnings for future sessions
cd $CLAUDE_OPC_DIR && uv run python scripts/core/store_learning.py \
  --session-id "short-id" \
  --type WORKING_SOLUTION \
  --content "what worked" \
  --tags "tag1,tag2" \
  --confidence high
```

## Project-Specific Rules

**Remote Execution**
- Code may run remotely in messy environments
- Don't execute heavy simulation logic - user will run it
- Assume shared disk filesystem - **NEVER remove folders**

**Documentation Sync**
- After code changes, check and update docs accordingly
- Keep README, comments, and docs in sync with implementation, use ADR (arch decisions records) way if proper

**Git Management**
- Read files before writing (especially git-tracked files)
- Never amend commits unless explicitly requested
- `tasks/todo_*.md` and `*.md` symlinks → not in git

**Python Environment**
- Prefer `uv` for environment management

**Communication**
- Provide high-level explanations at each step
- Focus on what changed and why
- Keep responses concise

## Code Review Before Submission

✅ **Checklist**
- [ ] Changes are minimal and focused
- [ ] Root cause addressed (not just symptoms)
- [ ] Documentation updated if needed
- [ ] No unnecessary abstractions added
- [ ] Errors fail explicitly
- [ ] Git-tracked files modified with caution
