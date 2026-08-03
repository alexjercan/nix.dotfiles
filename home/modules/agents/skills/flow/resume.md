# Discovering or resuming a flow

Read for every existing ID and after a context cut or loss. Disk is the state;
never guess chat history.

## Checkpoint

At `work`'s threshold, commit an atomic green step. Record the completed Step,
commit and check results, and next Step in TASK.md. A checkpoint makes no
lifecycle transition.

Ask the user to run `/clear`; an agent cannot invoke it. The fresh prompt is:

```
/flow <id>
```

Add only state that tools cannot discover, such as intentionally uncommitted
work or an external action. No conversation summary or phase status. Runtime
compaction is not a durable handoff.

## Inspect

Run `sprout ls` before `tatr show`; each row is `BRANCH TASK PATH`. A matching
TASK identifies `<task-root>` even when main reports WORKING. For legacy `-`
associations, inspect that worktree's task records, branch diff and uncommitted
changes for work belonging to `<id>`. If none match, use main. Stop and
diagnose multiple matches instead of guessing.

```bash
sprout ls
tatr -r <task-root> show <id>
tatr -r <task-root> context <id> --phase resume
```

The selected `tatr show` is authoritative. Context lists artifact presence;
read only the current phase's packet. A task in WORKING, REVIEWING, or
COMPOUNDING should have a worktree. If absent, check `git branch --list`
before re-sprouting.

## Route

Dispatch from ACTIVITY plus GATES, not old intent.

- WORKING: inspect the branch diff and literal Steps; finish only incomplete
  work or re-emit a proven pending gate.
- REVIEWING: read the latest REVIEW.md. Open BLOCKER/MAJOR findings route to
  fixes, not another review.
- RESOLUTION DONE: determine landing separately. A branch in `sprout ls` is not
  landed; without one, verify the default-branch log.

## Reconstruct a pending gate

No gate gets a lifecycle marker. Recompute evidence, then use `gates.md`:

- UNDERSTANDING -> NOTES_READY only with a `tasks/<id>/NOTES.md` carrying
  every required section and no unanswered blocking question. Anything less
  resumes understanding and rewrites it.
- PLANNING -> PLAN_READY only with executable Story, Steps, and DoD, plus
  `cmd:` proofs red on the base for the intended missing change. `PLAN` already
  earned with the cursor still at PLANNING is a blocked dependency: the gate
  landed, so resolve the block and re-run rather than re-planning.
- WORKING with `PLAN` earned and no review feedback -> WORK_DONE only with all
  Steps complete, committed implementation and records, a clean tree, and green
  automation.
- WORKING after REQUEST_CHANGES -> require answered findings, committed fixes,
  a clean tree, and green verification. Latest round divisible by three means
  WORK_DONE; otherwise transition to REVIEWING and dispatch review.
- `RESOLUTION: DONE` with its branch in `sprout ls` -> LAND_READY. Without the
  branch, use the default log to distinguish landed work from branch loss.

Missing evidence resumes the phase. `manual:` stays pending; never self-confirm
it. A committed APPROVE still in REVIEWING is an interrupted handoff: run
`tatr -r <task-root> flow <id>`. A committed retro in COMPOUNDING closes the
record through the same command, then LAND_READY.

## Reconcile and report

Visible work outranks ticks. Correct unticked completed work or ticked missing
work against the diff. State task, activity, earned gates, and half-done work;
then continue.
