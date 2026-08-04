# Approval gates

Read this when a phase or resume returns `UNDERSTANDING_DONE`, `PLANNING_DONE`,
`WORKING_DONE`, or `COMPOUNDING_DONE`. These gates are the only context-cut
approval protocol.

## Ask

Use the runtime's blocking user-question tool when it is available. Otherwise
ask one direct blocking question and end the turn. Offer:

- the approve label from the table, which names its transition or action;
- `Stop and let me decide`, which performs no transition or action;
- at `PLANNING_DONE` only, `Reject plan - back to understanding`.

Never treat silence, a new `/flow`, or prior approval of another gate as
approval. Summarize the phase result and inspection commands before asking.

| Gate | Approve label | Effect |
| --- | --- | --- |
| `UNDERSTANDING_DONE` | `Approve understanding - move to PLANNING` | Run `tatr -r <task-root> flow <id>`. |
| `PLANNING_DONE` | `Approve plan - earn the PLAN gate` | Run `tatr -r <task-root> flow <id>`. |
| `WORKING_DONE` | `Approve review - move to REVIEWING` | Run `tatr -r <task-root> flow <id>`. |
| `COMPOUNDING_DONE` | `Approve landing - land the branch` | Follow `landing.md`. |

A rejected plan is not a plan to redo: the decision it was built from is the
thing that failed. Run `tatr -r <task-root> rewind <id> --to UNDERSTANDING`,
carry what the user said into the reason, then dispatch `understand` from the
section their objection lands in. Never re-plan against the same decision.

Leaving `UNDERSTANDING` earns no gate, so `UNDERSTANDING_DONE` is a skills-level
approval and the cursor reaching `PLANNING` is the only evidence it landed.

Leaving `PLANNING` earns the `PLAN` gate and lands the cursor in `WORKING` in
one call. A cursor held at `PLANNING` with `PLAN` earned is a blocked
dependency or a foreign claim, not a failed approval: the gate is durable, so
resolve the block and re-run rather than re-planning.

`WORKING_DONE` covers initial work and a review continuation when the latest
round is a multiple of three.

## Continue or stop

After UNDERSTANDING_DONE, PLANNING_DONE or WORKING_DONE approval, perform the
transition
before the context cut. Then commit only the task records before the context
cut. Ask the user to run `/clear`, then `/flow <id>`, and end the turn.

For `Stop and let me decide`, leave all state unchanged and print: run
`/clear`, then `/flow <id>` when ready. End the turn.
