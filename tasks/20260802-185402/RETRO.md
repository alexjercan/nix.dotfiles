# Retro: Make the afk runner's output human readable

- TASK: 20260802-185402
- BRANCH: feature/afk-human-output
- REVIEW ROUNDS: 1

## What went well

The plan carried a literal target-output block, so "friendlier print format"
became a byte-level spec before any code existed. Both DoD tests were written
against it and both are red on the base branch for the intended reason, which
the review re-derived by swapping `master:afk.sh` back in (5 passed / 5
failed). One review round, APPROVE, no BLOCKER or MAJOR.

The "one content stream, TTY-gated decoration" decision made the off-TTY
guarantee a property of two variables rather than of a second code path, so
`afk-test.sh` asserts the exact text a human reads instead of a parallel
machine format nobody looks at.

## What went wrong

Nothing shipped broken, but the implementation hit two traps that the plan's
one-line "poll instead of block" step did not name:

- A blocking `read -t $HEARTBEAT` returns complete lines; a polling
  `read -t 0.2` saves partial input into the variable on timeout. The event
  loop needed a `partial` accumulator or long JSON events would be cut in
  half. The behaviour was confirmed directly against a real fifo rather than
  reasoned about.
- `stty size` under `script -qec` with a non-tty parent answers `0 0`. A
  presence-only guard accepted it, `TERM_COLS` became 0, and
  `${text:0:$((TERM_COLS - 1))}` silently degraded to "all but the last
  character" - a one-character test failure that read as an off-by-one.

Breadth: 327 insertions across two scripts is inherently whole-file. A
presentation rewrite touches every print site at once and there is no
independently landable half, so this is not a missed split.

Churn: zero review rework. Nothing to attribute to a plan-time question.

Context: no measured pressure. No checkpoint, no compaction, one worktree.
The review ran in a fresh session that entered at REVIEWING, which is the
designed out-of-context handoff rather than a symptom.

## What to improve next time

A plan step that says "replace a blocking read with a poll" is naming a
framing change, not a timing change. List what the old call guaranteed
incidentally - complete lines, ordering, back-pressure - as part of writing
that step, not while debugging it.

Environment probes belong behind a plausibility range, not an emptiness
check, from the first draft.

## Action items

- R1.1 (MINOR), R1.2 and R1.3 (NIT) in REVIEW.md are open and non-blocking.
  R1.1 - reprinting the session UUID so a failed unattended run has a direct
  `claude --resume` handle - is the one worth a follow-up task if the user
  wants it; it was deliberately absent from the approved target output.
- `manual: user judgement` is still pending: run `afk run` once in a real
  terminal before landing.
- Lessons submitted to `/home/alex/personal/agent-knowledge` (commit
  `ba38b18`): occurrences on `changes/refactors-preserve-incidental-contracts`
  and `testing/cross-the-real-boundary`, plus a new
  `verification/validate-a-probes-value-not-its-presence`.
