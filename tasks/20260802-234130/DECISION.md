# Decision: a batch stops at its first failure

- DATE: 20260802-234420
- STATUS: ACCEPTED
- TASK: 20260802-234130
- TAGS: afk, scripts

## Context

`afk run` gains a queue: several goals or task IDs, driven one after the
other. The queue introduces a policy question the single-argument runner never
had to answer - what happens to items 2..N when item 1 stops.

Every existing stop in afk is a disagreement between what a session claimed
and what tatr or git actually record: a marker for a foreign task, a gate
approval that did not cause its transition, a landing that produced no commit,
two sessions with an identical fingerprint. None of them are transient.

## Decision

Fail fast. The first item that stops ends the whole batch, non-zero, and the
runner prints the arguments it never started so the human can re-issue them.
Each item gets its own session counter and its own `AFK_MAX_SESSIONS` budget.
The whole queue is validated - every task-ID-shaped argument must exist -
before the first Claude session runs.

## Alternatives considered

- Continue with the next item and report a per-item verdict at the end. It
  reads like a friendlier CI, but it is wrong for this tool: afk stops
  precisely when it can no longer trust the state it is standing on, and the
  next goal would be built on that state - most items share the same
  repository and the same main branch. It would also bury the one failure that
  needs a human under later output.
- A batch-wide `AFK_MAX_SESSIONS`. Rejected: the bound exists to catch one
  task going nowhere, and sharing it would let a long first item starve the
  last.
- Validate each argument lazily, when its turn comes. Rejected: a typo in the
  third ID would surface after the first two had already landed, which is the
  worst possible time to find it.

## Consequences

- A stopped batch is resumable by hand, not automatically: `afk run` the
  reported remaining arguments once the stop is understood.
- `die` and `on_signal` grow a dependency on the queue state, so the
  not-started line has to be suppressed when there is no queue yet (a bad
  argument count, or no git repository).
- Items are not isolated from each other: they share the main checkout, so
  item 2 plans against whatever item 1 landed. That is the intended reading of
  "sequentially" and is why continue-on-error is unsafe.
