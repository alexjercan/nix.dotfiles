# Retro: cover the afk SPIN_MSG CR/ESC sanitizer with a test

- TASK: 20260802-205434
- BRANCH: test/afk-spin-control-bytes
- REVIEW ROUNDS: 1

## What went well

- The plan named the per-mutation redness as its own DoD clause, so "the test
  is red if `\r` is dropped" and "red if `\033` is dropped" were separate proofs
  rather than one aggregate. Review re-ran both from scratch and got the
  recorded failure lines byte for byte.
- The plan pre-computed the prefix width (~34 chars) and chose 80 columns from
  it. Copying the wrap test's 40 would have truncated the payload away and the
  test would have passed vacuously.

## What went wrong

- Nothing that reached review: round 1 was APPROVE with no findings.
- One plan prediction was wrong in detail. It expected a leaked CR to show only
  as a frame missing its trailing `\033[?7h`; under the real mutation it also
  drops the "carries the message past the stripped escape" assertion, because
  the CR splits the chunk before `gamma` is written. The prediction seemed sound
  because the CR analysis stopped at the frame's own boundary and did not follow
  where inside the frame the split lands. Harmless here - two specific signals
  instead of one - but it was a guess presented as a mechanism.

## What to improve next time

- Breadth: 61 test lines plus records. No split was missed; the task was seeded
  from a single review finding and stayed that size.
- Churn: none. The from-scratch challenge in `plan` had already rejected the
  `SPIN_MSG` unit seam and the fold-into-the-wrap-test option, and both
  rejections held up under review.
- Context: no threshold crossing, compaction warning, handoff or delegation was
  observed on this task.

## Action items

- None. The one reusable observation was submitted through `knowledge` as an
  occurrence on `verification/negated-checks-pass-vacuously` (body unchanged -
  the existing lesson already states the guard), committed centrally as
  `b8cd782`. `knowledge check` exits 0.
