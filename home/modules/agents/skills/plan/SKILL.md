---
name: plan
description: Turn a request into tatr tasks with ordered Steps and proof-bearing done criteria. Use for `/plan`, or for work needing scoping first.
---

# Plan - Request to Implementable Tasks

The output of planning is not code. It is `tasks/<id>/TASK.md` files a cold
session can execute top to bottom.

## Workflow

1. **Understand.** Read the request, any named TASK.md, the sibling artifacts
   `tatr context <id> --phase plan` lists, and the relevant code. Check the
   backlog (`tatr ls --sort priority`) so the plan extends it instead of
   duplicating it.

   If the open question is what to build rather than how, invoke `spike`
   first. If the request fixes only where a thing goes or how it looks but not
   WHICH thing it is, pin that down with the user - and put the constraint
   that makes the candidates mutually exclusive in front of them, because that
   incompatibility is usually the real decision. Do not ask about what the
   code or a sensible default already answers.

2. **Decide the breakdown.** One cohesive change stays ONE task. Split only
   when the pieces are independently implementable and committable, or when
   the user explicitly asked for an epic, sprint, version, release or
   multi-feature container (flow's `epic.md`).

3. **Create the tasks.**

   ```bash
   tatr new "Short imperative title" -p <priority> -t <tags> -b <body-file>
   ```

   ONE `tatr new` per command, never chained - a same-second ID collision
   fails the call. Priorities are relative to the existing backlog, higher
   first. Hard ordering goes in `-d <id>`, not in priority. If the user named
   an existing task, edit that task; do not create a duplicate.

4. **Write Steps and the Definition of Done.** This is the heart of the plan.
   Steps are concrete verifiable actions in execution order, each naming the
   files it touches. Every DoD item names its proof.

   Record in Notes the files and facts you discovered, the assumptions, and
   the open questions. A step that encodes a mechanism, a formula, or a
   dependency's ordering must cite the file that verifies it or be phrased as
   "confirm X, then ..." - a reasoned verdict about a dependency is a
   hypothesis, not evidence. Load-bearing git or nix semantics get verified in
   a throwaway scratch repo first.

   Phrase a conditional step as a checkable decision ("decide X: do, or defer
   with reason"), never "Optional: do X" - a deferred optional step leaves a
   closed task with an unchecked box and no honest tick.

   A load-bearing architectural choice gets a decision record.

5. **Present.** List the task IDs and titles in order, the done-definition,
   and the assumptions to double-check. Under `flow`, this is the hard gate:
   stop and wait. `tatr flow <id> --to PLANNED` writes `PLAN STATUS: APPROVED`
   and is the only thing that may.

## Guidelines

- Do not pad. A three-line change gets a three-line plan.
- Run each `cmd:` proof against the BASE branch at plan time; a proof already
  red before the work starts is a broken proof, not a criterion.
- When a task adds a new route into an existing state or mode, plan a step
  that greps for everything gated on that state and lists what newly runs in
  the new context.
- Do not plan from a model of the system; plan from the system.

## Output

Under `/plan`: task IDs, titles, assumptions. Offer to commit the task files.
Do not implement.

Under `/flow`: the done-definition, the ordered Steps, and any decisions -
250 words or fewer, ending with `PLANNED <id>`.

## Load on demand

Read one ONLY when its condition holds. Never preload them.

- writing the Definition of Done, or judging a proof -> `proofs.md`
- a load-bearing architectural or interface fork was made -> `decision.md`
- an irreversible fork, independent domains, an oversized Epic, or a lanes request -> `lanes.md`
