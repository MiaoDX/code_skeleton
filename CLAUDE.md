# Guidelines

1. First think through the problem, read the codebase for relevant files, and write a plan to file:
* if you are codex cli, write to `tasks/todo_codex.md`
* if you are claude code cli, write to `tasks/todo_cc.md`
* if you are gemini cli, write to `tasks/todo_gemini.md`
2. The plan should have a list of todo items that you can check off as you complete them
3. Before you begin working, check in with me and I will verify the plan.
4. Then, begin working on the todo items, marking them as complete as you go.
5. Please every step of the way just give me a high level explanation of what changes you made
6. Make every task and code change you do as simple as possible. We want to avoid making any massive or complex changes. Every change should impact as little code as possible. Everything is about simplicity.
7. Finally, add a review section to the `tasks/todo_xx.md` (according to who you are) file with a summary of the changes you made and any other relevant information.
8. DO NOT BE LAZY. NEVER BE LAZY. IF THERE IS A BUG FIND THE ROOT CAUSE AND FIX IT. NO TEMPORARY FIXES. YOU ARE A SENIOR DEVELOPER. NEVER BE LAZY
9. MAKE ALL FIXES AND CODE CHANGES AS SIMPLE AS HUMANLY POSSIBLE. THEY SHOULD ONLY IMPACT NECESSARY CODE RELEVANT TO THE TASK AND NOTHING ELSE. IT SHOULD IMPACT AS LITTLE CODE AS POSSIBLE. YOUR GOAL IS TO NOT INTRODUCE ANY BUGS. IT'S ALL ABOUT SIMPLICITY
10. Obey zen of python if possible

# Custom

1. After update code changes, check the docs too, update docs as needed to meet the code changes
2. We may run the code remotely, so code env can be messy, DO NOT run python codes with isaac related logic, the user will run for you.
3. You can read any files without further permission, and write to any file not being tracked by git. But for files with git, please with caution.
4. Do less try-catch, just fail aloud and early. Fail explict is much better than silient fake-success
5. When updating `todo_xx.md`, if it's too long, clean it too.
6. Some of the codes will run on server with shared disk filesystem, so NEVER DO FOLDER REMOVING if possible
7. All `tasks/todo_xx.md` and `XXX.md` softlinks should not be included in git control
8. Never git amend unless specifically required


# Project context

## Required behavior

- Before writing code, search these folders and quote the exact section/line used.
- If uncertain, search the local file or doc first, then proceed.
- Explain the changes before editing code

## Sources to consult BEFORE proposing code

You are coding for **NVIDIA Isaac Sim 5.x** (Kit 107+). Do **not** use 4.x/4.5-only APIs.

- `refs/isaac-sim-doc.<VERSION>.md`  (mirrored 5.x docs pages: release_notes, requirements, templates, ROS/Perception/etc.)
- `refs/isaac-sim-code.<VERSION>.md` (checked-out Isaac Sim codes/samples)
- `refs/isaaclab.<VERSION>.md` (checked-out Isaac Lab codes/samples)

## Python env

Prefer to use **uv** for Python environment management.

## VLM API

For MIFY LLM API, wlways add unique request IDs calls to prevent response caching: `extra_headers={"X-Model-Request-Id": str(uuid.uuid4()), "X-Conversation-Id": str(uuid.uuid4())}`. 
- DO NOT SHOW previous chats' history unless necessary, concentrate on current problem
