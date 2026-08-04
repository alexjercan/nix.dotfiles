---
name: understand
description: Confirm the problem, gather context, weigh ideas, and record the decision before anything is planned. Use for `/understand` or a new goal.
---

# Understand - Decide What To Build

Own the question, not the code. Produce `tasks/<id>/NOTES.md` and a
`DECISION.md`, then return `UNDERSTANDING_DONE`. Leave TASK.md as `tatr new`
left it; planning fills it in.

## Workflow

1. Read `tatr -r <task-root> context <id> --phase understand` and the code the
   goal names. State the problem in your own words - the pain, not a solution -
   and confirm it with the user before anything else. A rejection sends you
   back to restating it.
2. Write `## Problem Statement`: the confirmed problem, and what it explicitly
   is not.
3. Build `## Context`: the code, constraints, prior decisions and dependencies
   the answer must respect. Ask the user for what the tree cannot tell you.
   Carry every stated constraint verbatim - the ideators read this file and
   nothing else.
4. Ideate, then rank the pitches into `## Ideas`, best first.
5. Put your recommendation to the user as concrete choices, not a summary:
   which shape, which data structure, what stays out of scope. Rejected
   choices return to step 4; a changed problem returns to step 1.
6. Record the settled choice with
   `tatr -r <task-root> scaffold <id> DECISION`, filled from the winning idea
   and the losing ones. Commit both records. Return `UNDERSTANDING_DONE`.

Where the tree leaves WHAT unknown rather than merely undecided - an
unanswered external question, a behavior nobody has run - gather the evidence
here. The phase does not end on a guess.

## Rules

- One question at a time, and never one the code answers.
- No section reaches NOTES.md before it is confirmed.
- KISS and YAGNI judge every idea. A mode, wrapper, option or extension point
  with no named requirement in this task loses to the version without it.
- No implementation, no branch, no worktree.

## Output

The confirmed problem in one line, the ranked ideas with their costs, the
decision and the constraint that chose it, open assumptions, and the record
paths. At most 150 words. Return `UNDERSTANDING_DONE <id>` and transition
nothing; flow owns the gate.

## Load on demand

- confirming the problem, asking for context, or putting choices to the user -> `dialogue.md`
- writing or ranking a NOTES.md section -> `notes.md`
- ideating solutions, alone or in lanes -> `ideation.md`
- an external fact, or a behavior only a prototype can settle -> `evidence.md`
- writing, superseding or formatting the decision record -> `decision.md`
