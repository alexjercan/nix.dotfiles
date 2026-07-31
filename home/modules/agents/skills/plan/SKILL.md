---
name: plan
description: Turn a request into tatr tasks with ordered Steps and proof-bearing done criteria. Use for `/plan`, or for work needing scoping first.
---

# Plan - Request to Implementable Tasks

Output: `tasks/<id>/TASK.md` a cold session can execute top to bottom.

## Workflow

1. Read the request, named task, `tatr context <id> --phase plan` artifacts,
   relevant code, and `tatr ls --sort priority`. Invoke `spike` when WHAT is
   unknown. Ask only when code cannot answer; state the mutually exclusive
   constraint.
2. Keep one cohesive change as one task. Split only independently
   implementable/committable pieces or an explicit multi-feature container.
3. Create with
   `tatr new "<imperative title>" -p <priority> -t <tags> -b <body-file>`.
   Run one creation per command. Priority is soft ordering; `-d` is hard
   ordering. Update a named existing task, never duplicate it.
4. Write ordered, verifiable Steps naming touched files. Every DoD item names
   its proof. Notes hold discovered files/facts, assumptions, and questions.
   Cite evidence for mechanisms and ordering, or say `confirm X, then ...`.
   Verify load-bearing git/Nix semantics in a scratch repo. Phrase conditional
   work as `decide X: do, or defer with reason`. Record load-bearing choices
   in DECISION.md.
5. Present IDs/titles, DoD, Steps, assumptions, and decisions. Under `flow`,
   STOP for approval; only `tatr flow <id> --to PLANNED` records it.

## Rules

- No padding. Plan from the system, not a remembered model.
- Plan the simplest design that satisfies the DoD. Generality, options, and
  extension points need a caller in this task, or they are deferrals.
- Run each `cmd:` proof on the base branch; it must be red for the intended
  missing change.
- A new route into a state/mode requires a grep step listing all newly active
  gates.

## Output

`/plan`: IDs, titles, assumptions; offer to commit task files. No
implementation. Under `/flow`: DoD, ordered Steps, decisions; at most 250
words, ending `PLANNED <id>`.

## Load on demand

- writing DoD or judging a proof -> `proofs.md`
- load-bearing architecture/interface choice -> `decision.md`
- irreversible fork, independent domains, oversized Epic, or requested lanes -> `lanes.md`
