---
name: plan
description: Turn a request into tatr tasks with ordered Steps and proof-bearing done criteria. Use for `/plan`, or for work needing scoping first.
---

# Plan - Request to Implementable Tasks

Output: `tasks/<id>/TASK.md` a cold session can execute top to bottom.

## Workflow

1. Read the request, named task,
   `tatr -r <task-root> context <id> --phase plan` artifacts, relevant code,
   and `tatr ls --sort priority`. Use `spike` when WHAT is unknown. Ask only
   when code cannot answer; state the mutually exclusive constraint.
2. Keep one cohesive change as one task. Split only independently
   committable pieces or an explicit multi-feature container. Name touched
   ownership boundaries. Size to one understand-build-review pass. A task
   needing a throwaway shim or broken intermediate state does not split -
   record the reason and its breadth instead.
3. Create with
   `tatr new "<imperative title>" -p <priority> -t <tags> -b <body-file>`.
   Run one creation per command. Priority is soft ordering; `-d` is hard
   ordering. Update a named existing task, never duplicate it.
4. Write ordered, verifiable Steps naming touched files. Every DoD item names
   its proof. Notes hold discovered files/facts, assumptions, and questions.
   Cite evidence for mechanisms and ordering, or say `confirm X, then ...`.
   Verify load-bearing git/Nix semantics in scratch. Phrase conditional
   work as `decide X: do, or defer with reason`. Record load-bearing choices
   in DECISION.md.
5. Present via Output. Under `flow`, lifecycle stays PLANNING; flow owns the
   approval gate. Its approved `tatr -r <task-root> flow <id> --to PLANNED`
   records approval.

## Rules

- No padding. Plan from the system, not a remembered model.
- Plan the simplest design that satisfies the DoD: knowing the current
  constraints, would we build this route from scratch? Keep a concept budget -
  every mode, branch, option, wrapper, extension point, generality, or
  abstraction needs a
  named requirement, caller, or invariant in this task, or it is deferred.
- File and line counts prompt an inspection, never a design verdict.
- Run each `cmd:` proof on the base branch; it must be red for the intended
  missing change.
- A new route into a state/mode requires a grep step listing all newly active
  gates.

## Output

`/plan`: IDs, titles, assumptions; offer to commit task files. No
implementation. Under `/flow`: concise operator plan - what changes, ordered
Steps, DoD proofs, assumptions, decisions, and inspection commands. Return
the gate status `PLAN_READY <id>` without changing lifecycle state.

## Load on demand

- writing DoD or judging a proof -> `proofs.md`
- load-bearing architecture/interface choice -> `decision.md`
- irreversible fork, independent domains, oversized Epic, or requested lanes -> `lanes.md`
