---
name: grill-with-docs-batch
description: Grouped grilling session that wraps grill-with-docs semantics while discussing related questions in batches. Use when the user wants to stress-test a plan against docs and domain language faster than one-question-at-a-time grilling, without lowering documentation or decision quality.
---

# Grill With Docs Batch

Challenge a plan against the repository's domain model and documentation like
`grill-with-docs`, but move in small coherent batches instead of one question at
a time.

## Core Rule

Keep the quality bar of `grill-with-docs`:

- Challenge vague or overloaded terms against `CONTEXT.md` or `CONTEXT-MAP.md`.
- Explore code and docs instead of asking questions that local context can answer.
- Use concrete scenarios and edge cases to force precise boundaries.
- Update `CONTEXT.md` inline as soon as glossary terms are resolved.
- Offer ADRs only when a decision is hard to reverse, surprising without
  context, and the result of a real trade-off.

The only behavioral change is pacing: ask grouped questions when the questions
belong to the same decision layer and can be answered together.

## Batch Shape

Each batch should contain 3-6 tightly related questions. Use fewer when the
decision is risky or highly dependent.

```text
Batch N: <short theme>

Assumptions from docs/code:
- <what was verified locally>

Questions:
1. <decision question>
   Recommended answer: <clear default and why>
2. <decision question>
   Recommended answer: <clear default and why>

If accepted, I will update:
- CONTEXT.md: <terms/relationships>
- ADR: <only if warranted, otherwise "none">
```

Wait for the user's response before applying docs or moving to the next batch.
Accept shorthand answers such as "all agree", "1 yes, 2 no because...", or
"change 3 to...".

## When To Fall Back To One Question

Ask one question at a time when:

- A term conflicts with the current glossary and affects every later question.
- The user's answer could materially change the batch structure.
- A decision touches public contracts, private data boundaries, safety policy,
  security, irreversible file moves, or external paid/model infrastructure.
- Local docs/code contradict the user's premise.

## Documentation Discipline

After each accepted batch:

1. Apply only the resolved `CONTEXT.md` glossary/relationship updates.
2. Keep `CONTEXT.md` free of implementation details, plans, and progress notes.
3. If an ADR is warranted, create or update it separately with clear context,
   decision, alternatives, and consequences.
4. Report exactly what changed before asking the next batch.

## Language

Mirror the user's language for the discussion. Keep questions direct and include
your recommended answer for each question.
