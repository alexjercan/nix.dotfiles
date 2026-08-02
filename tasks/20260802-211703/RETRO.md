# Retro: afk: rotate the session on a soft/hard context token limit

- TASK: 20260802-211703
- BRANCH: feature/afk-token-limit-rotation
- REVIEW ROUNDS: 2

## What went well

- The plan named its one conditional claim (do `tool_result` events reach
  `stream-json` stdout?) and made the design contingent on it, so it was
  checked against a live run before any code depended on it.
- The hard limit's inertness was caught by a timing assertion, not by luck:
  the cases assert WHEN the stop lands against a fixture pause, so a stop that
  never fired read as a failure instead of a pass.
- Both round 1 fixes were falsified against mutated copies of `afk.sh` before
  being kept, and round 2 re-ran that falsification independently.

## What went wrong

- Breadth: 191 lines of `afk.sh` and 201 of tests, and the diff does not split.
  The new outcome is one thread - `KILL_REASON` set in `run_claude`, carried
  past three fatal checks, routed by `cmd_run` and both gate helpers - and any
  cut lands a runner that stops sessions it cannot route. Large, not sprawling.
- Churn, R1.1: the plan asserted the safe boundary as "the next `user` event
  carrying a `tool_result`", which is a claim about the stream's CARDINALITY,
  not its existence. The live check answered "do these events arrive?" and was
  read as answering "how many arrive per turn?". It seemed sound because the
  observed transcripts do carry one result per event - the missing question was
  how many tools a single turn issues (9.4% issue more than one).
  `plan/decision.md`'s cold-reader test is where it would have surfaced:
  "the only event that proves no tool is mid-execution" invites "which tool?"
  from any reader who has seen a parallel turn.
- Churn, R1.2: a Step was ticked naming a branch ("a stopped landing gate
  rotates rather than dying on 'produced no commit'") that no proof pinned.
  The DoD enumerated behaviors of the limits, and the landing arm is a
  hand-written twin of `lifecycle_gate` rather than a call to it, so it fell
  outside every listed behavior while looking covered.
- Context: no threshold crossing, compaction warning, delegation or handoff is
  recorded in this task. Each review round ran as its own fresh session
  entering at REVIEWING, which is the out-of-context default working as
  intended, not pressure.

## What to improve next time

- When a design hangs on the shape of an external event stream, verify its
  cardinality and grouping against the real corpus, not only that the events
  exist. "One per turn" and "one per event" are different claims.
- When a Step's text names a specific code branch, the DoD needs a proof for
  that branch. Duplicated-by-hand helpers are where such branches hide.

## Action items

- None. Both findings are fixed and covered; the `LAND_READY` arm's
  duplication of `lifecycle_gate` was judged a shape to watch, not a defect in
  this diff.
