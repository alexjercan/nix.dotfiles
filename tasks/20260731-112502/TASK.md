# Add an honest retire path for superseded tasks

- STATUS: OPEN
- PRIORITY: 60
- TAGS: chore,tatr,flow
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

As a task author, I want a way to retire a task that should not be worked, so
that a superseded or duplicated record does not have to choose between staying
OPEN forever and having a review and retro fabricated for work nobody did.

## Steps

- [ ] Confirm the gap on the released binary: from BACKLOG the only path to
      `STATUS: CLOSED` is the full walk to DONE, and DONE is gated behind a
      REVIEW.md whose latest verdict is APPROVE plus the COMPOUNDING step.
      `tatr edit` has no `--status`, so `tatr rm` is the only alternative and
      it destroys the record.
- [ ] Decide the shape with the user: a terminal `DROPPED`/`SUPERSEDED` flow
      step reachable from any non-DONE step and requiring a reason, versus a
      `tatr close <id> --superseded-by <id> --reason <text>` command, versus
      keeping `tatr rm` and treating removal as the answer.
- [ ] Implement it in the tatr repo with a guard test, then teach the flow
      skills when to use it instead of `tatr rm`.
- [ ] Decide whether `tatr check` should require a superseded record to name
      what superseded it.

## Definition of Done

- A task can reach a terminal retired state without a REVIEW.md or a RETRO.md
  (test: name the tatr checker test once the shape is chosen).
- The retired state records WHY and, when applicable, what superseded it
  (test: same).
- The flow-family skills name the retire path where they currently have none
  (cmd: `grep -rn "supersed" /home/alex/personal/nix.dotfiles/home/modules/agents/skills`).

## Notes

- Found in 20260730-155003. Its plan said "close 20260731-104819 as superseded
  via `tatr edit`"; no such option exists, and the lifecycle offers no honest
  terminal state for a task whose work another task absorbed. `tatr rm` was
  used there instead, with the rationale preserved in that task's DECISION.md
  and in the Epic's Notes, because the alternative was fabricating an APPROVE
  verdict for work that never happened.
- Cross-repository: the mechanism lands in /home/alex/personal/tatr, the skill
  wording in this repository.
