# Guidelines

1. First think through the problem, read the codebase for relevant files, and write a plan to `tasks/todo.md`.
2. The plan should have a list of todo items that you can check off as you complete them
3. Before you begin working, check in with me and I will verify the plan.
4. Then, begin working on the todo items, marking them as complete as you go.
5. Please every step of the way just give me a high level explanation of what changes you made
6. Make every task and code change you do as simple as possible. We want to avoid making any massive or complex changes. Every change should impact as little code as possible. Everything is about simplicity.
7. Finally, add a review section to the `tasks/todo.md` file with a summary of the changes you made and any other relevant information.
8. DO NOT BE LAZY. NEVER BE LAZY. IF THERE IS A BUG FIND THE ROOT CAUSE AND FIX IT. NO TEMPORARY FIXES. YOU ARE A SENIOR DEVELOPER. NEVER BE LAZY
9. MAKE ALL FIXES AND CODE CHANGES AS SIMPLE AS HUMANLY POSSIBLE. THEY SHOULD ONLY IMPACT NECESSARY CODE RELEVANT TO THE TASK AND NOTHING ELSE. IT SHOULD IMPACT AS LITTLE CODE AS POSSIBLE. YOUR GOAL IS TO NOT INTRODUCE ANY BUGS. IT'S ALL ABOUT SIMPLICITY

# Project context

You are coding for **NVIDIA Isaac Sim 5.0** (Kit 107+). Do **not** use 4.x/4.5-only APIs.
Prefer examples from our local docs and SDK paths below.

## Sources to consult BEFORE proposing code
- `refs/isaac-sim-doc.xml`  (mirrored 5.0 docs pages: release_notes, requirements, templates, ROS/Perception/etc.)
- `refs/isaac-sim-code.xml` (checked-out Isaac Sim codes/samples)

## Required behavior
- Before writing code, search these folders and quote the exact section/line used.
- If you see any `omni.isaac.*` imports or 4.x-only symbols, map to the 5.0 `isaacsim.*` equivalents or updated APIs and show the 5.0 doc snippet.
- If uncertain, open the local file or doc first, then proceed.
