---
name: plan
description: Turn a request into tatr tasks with ordered Steps and proof-bearing done criteria. Use for `/plan`, or for work needing scoping first.
---

# Plan - Decision to Implementable Task

Understanding chose what to build. This phase asks whether that is a sound
starting point, then writes `tasks/<id>/TASK.md` a cold session can execute.

## Workflow

1. Read `tatr -r <task-root> context <id> --phase plan`, `DECISION.md`,
   NOTES.md and the code they name. The decision is authority; NOTES.md is
   input. Ask only what neither the records nor the code answer.
2. Challenge the starting point before writing Steps: does the chosen shape
   survive the code as it is now? A real problem goes to the user with what it
   breaks, and rewinds to `understand` rather than being planned around.
3. Keep one cohesive change as one task. Split only independently committable
   pieces, wiring the split with `-d`. Name touched ownership boundaries. Size
   to one understand-build-review pass. A task needing a throwaway shim or
   broken intermediate state does not split - record the reason instead.
   Create with
   `tatr new "<imperative title>" -p <priority> -t <tags> -b <body-file>`,
   one per command, updating a named existing task rather than duplicating it.
4. Write ordered, verifiable Steps naming touched files. Every DoD item names
   its proof. Notes hold discovered files/facts, assumptions, and questions.
   Verify load-bearing git/Nix semantics in scratch. Phrase conditional
   work as `decide X: do, or defer with reason`.
5. Present via Output. Under `flow`, lifecycle stays PLANNING; its approved
   `tatr -r <task-root> flow <id>` earns the `PLAN` gate.

## Rules

- No padding; plan from the code, not a remembered model.
- Plan the decision, nothing beside it. A mode, option, wrapper or
  abstraction the decision did not choose needs a named requirement or caller
  in this task, or it is deferred.
- File and line counts prompt an inspection, never a design verdict.
- Run each `cmd:` proof on the base branch; it must be red for the intended
  missing change.
- A new route into a state/mode requires a grep step listing all newly active
  gates.

## Output

`/plan`: IDs, titles, assumptions; offer to commit task files. No
implementation. Under `/flow`: concise operator plan - what changes, ordered
Steps, DoD proofs, assumptions, and inspection commands, plus any reason this
plan might not hold, stated as a risk rather than buried. Return the gate
status `PLANNING_DONE <id>` without changing lifecycle state.

## Load on demand

- writing DoD or judging a proof -> `proofs.md`
- irreversible fork, independent domains, oversized goal, or requested lanes -> `lanes.md`
