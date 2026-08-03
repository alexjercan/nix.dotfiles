# Understanding - brief the change before it is planned

Read when the task is new or its ACTIVITY is UNDERSTANDING. It produces one
artifact, `tasks/<id>/NOTES.md`, and one gate, `NOTES_READY`.

## Phase

1. Read `tatr -r <task-root> context <id> --phase understand`, then the code
   the goal names and its neighbors. Read the tree, not a remembered model.
2. Restate the goal in one line. Ask a blocking question only where two
   readings produce materially different work; otherwise record the assumption
   and keep going. If reading the tree leaves WHAT unknown rather than
   ambiguous, write no NOTES.md and take the router's `spike` route.
3. Write `tasks/<id>/NOTES.md` in the shape below.
4. Present it and return `NOTES_READY <id>`. Transition nothing; flow owns the
   gate.

## Shape of NOTES.md

```markdown
# Notes: <title>

## What changes
## Surfaces
## Data and interfaces
## Sketches
## Shape
## Consequences and open questions
```

- What changes: the user-visible behavior, before and after.
- Surfaces: every file, module or crate touched, one line of why for each.
- Data and interfaces: the data structures, functions, methods and types added
  or changed, with signatures.
- Sketches: a few indicative diff lines per key change, marked illustrative.
  Never a full patch.
- Shape: an ASCII flow or component diagram; mermaid only where ASCII cannot
  carry the shape.
- Consequences and open questions: what this costs, what it forecloses, and
  what is still unanswered.

Aim it at a human reading cold, who has not seen the code and wants to know
what the change will do and where it lands.

## A scratchpad, not a spec

`TASK.md` stays the plan's authority and the only record `tatr` gates on.
NOTES.md carries no proof and is not maintained once work starts: a stale
section is expected there, and no later phase is bound by it. Planning reads
it as input.
