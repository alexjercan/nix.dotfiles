# Retro: afk run accepts a batch of goals or task IDs and runs them sequentially

- TASK: 20260802-234130
- BRANCH: feat/afk-run-batch
- REVIEW ROUNDS: 1

## What went well

Doing the extraction as its own step, with the suite green before anything
else moved, meant every later red run had exactly one candidate cause. The
queue on top of `run_item()` is about twenty lines.

The plan named `prev_fp` explicitly - "`require_progress` reads it from its
caller's scope, so `run_item` must declare `local prev_fp=""`". That is the
kind of detail a per-item extraction silently gets wrong, and naming it in the
step is why it was not gotten wrong.

DECISION.md was written before the code, so fail-fast, the per-item
`AFK_MAX_SESSIONS`, and up-front queue validation each arrived with a recorded
alternative. The review had nothing to argue with because the argument was
already on disk.

Round 1 approved with no BLOCKER and no MAJOR; the five findings are three
MINORs and two NITs, all deferred to a follow-up task.

## What went wrong

`$SECONDS` was wrong the moment there was a second item, and nothing in the
plan flagged it as a risk of the extraction - it was found by reading the
summary line, not by a test. It looked correct for a year because a
process-wide counter and a single item's duration are the same number when
there is exactly one item.

`gen_work_to_land` read the task ID from `$AFK_TEST_TMP/task_id` at side-script
run time. One shared slot cannot describe two tasks, so the first two-task
test forced the ID to become a generation-time argument: four heredocs
unquoted, every run-time variable escaped, eighteen call sites updated. The
plan estimated three.

Seeding two tasks in one sandbox collides - `tatr` mints IDs from the wall
clock at second resolution - and `seed_working_task` returned an empty ID on
the second call. Diagnosed from `tatr.c:1058: same-second ID collision` in the
first red run. The retry that fixed it is unbounded with stderr discarded,
which the review flagged: it now recovers from the collision and hangs on
anything else.

The per-item elapsed fix ships unpinned. Reverting `item_started` leaves all
18 tests green, because every sandbox item finishes inside the same wall
second. Three real batch tests were written and the sabotage question was
still never asked of that one step.

## What to improve next time

- When a plan step says "update its N call sites", grep the count while
  writing the step. Three versus eighteen is the difference between a step and
  a session.
- When a change generalizes one of a thing to N, list every process-scoped
  variable the old code read and decide per item or per run for each. `SECONDS`
  was the one here; `prev_fp` and `TASK_ID` were caught only because the plan
  named them by hand.
- A retry loop written to absorb one known failure should name that failure and
  fail on everything else. `2> /dev/null` in a test fixture converts a red
  suite into a suite that never returns.
- Ask "would this step's test fail if I reverted the step?" per step, not per
  task. Two of the plan's steps had no proof of their own and only one was
  noticed.

## Action items

- 20260803-000029 - close R1.1, R1.2 and R1.3 from
  `tasks/20260802-234130/REVIEW.md`.
- R1.4 and R1.5 are NITs folded into the same follow-up if it is convenient;
  neither is worth its own task.

## Diagnosis

- Breadth: 382 insertions over 4 files, but roughly two-thirds is mechanical
  fixture churn from parameterizing `gen_work_to_land` across eighteen call
  sites. Not a missed split - the extraction, the queue and the fixture change
  are inseparable, and neither half is independently landable.
- Churn: none. Round 1 approved, no rework cycle, so no plan-time question
  would have saved a round. The findings that did land are all things a
  from-scratch challenge would not have surfaced either; they are consequences
  of the fixture's age, not of the plan's design.
- Context: no threshold crossing, compaction warning, rotation or checkpoint
  was recorded on this task. One handoff by design - review ran as a fresh
  `/flow` session entering at REVIEWING, which is the out-of-context reviewer
  the skill asks for.

## Knowledge

Three occurrences added to existing central lessons; no new slug was needed.

- `changes/refactors-preserve-incidental-contracts` - the `$SECONDS` case.
- `testing/control-shared-state` - the single-slot `task_id` fixture.
- `testing/prove-the-test-can-fail` - the unpinned elapsed-time step.
