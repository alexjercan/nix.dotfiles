# Decision: Update flow skills and afk for tatr v1.0.0 lifecycle

- DATE: 20260802-225248
- STATUS: ACCEPTED
- TASK: 20260802-223038
- TAGS: lifecycle, afk, skills

## Context

tatr v1.0.0 split the single `FLOW STEP` chain into `ACTIVITY` (a nullable
cursor), `GATES` (an accumulating set) and `RESOLUTION` (nullable, terminal),
and dropped `tatr flow --to`. `tatr flow <id>` now advances exactly one
activity and runs that activity's exit gate; leaving `PLANNING` earns `PLAN`
and lands the cursor in `WORKING` in one call.

## Decision

1. The plan gate's approval performs `PLANNING -> WORKING` itself, so `work`
   transitions nothing. It confirms `ACTIVITY: WORKING` with `PLAN` earned and
   stops otherwise.
2. afk's post-plan-gate assertion is the `PLAN` gate, not the `WORKING`
   cursor. `lifecycle_gate()` therefore takes a postcondition KIND (`gate` or
   `activity`) alongside its value: `PLAN_READY` asserts the gate, `WORK_DONE`
   asserts the `REVIEWING` cursor, because that edge earns nothing.
3. `phase_label()` prints a resolved record's RESOLUTION verbatim rather than
   the literal word `DONE` the plan named.

## Alternatives considered

1. Having `work` walk the cursor: not available. `flow` is the sole gate
   writer and `PLAN` is earned by leaving `PLANNING`, so the transition cannot
   be deferred to the phase that follows it.
2. Asserting the `WORKING` cursor after the plan gate: rejected. Leaving
   `PLANNING` with an open dependency or a foreign claim prints
   `gate PLAN recorded`, holds the cursor and exits 1. The gate is the durable
   half; calling that run a failed approval would be a lie, and the existing
   no-progress fingerprint already stops a run that then gets nowhere.
3. Printing the literal `DONE` for any resolution: rejected. A record closed
   `WONTDO` would report as finished work. Printing the resolution costs
   nothing and cannot lie; `RESOLUTION: DONE` still reads `DONE`, which is what
   every assertion and the landing gate want.

## Consequences

- The `WORKING` transition is committed in the main checkout before the sprout
  worktree exists. This is consistent with `gates.md`, which already commits
  task records before the context cut.
- `fingerprint()` hashes all three lifecycle fields, so a session that only
  earned a gate counts as durable progress.
- afk's landing gate keys off `RESOLUTION: DONE`, and task existence is now
  `tatr show`'s exit status: a task with no activity is a real task, so the
  old non-empty-field test no longer holds.
