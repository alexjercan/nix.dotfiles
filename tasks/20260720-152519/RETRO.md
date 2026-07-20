# Retro: Work skill: docs-sync rule - doc surfaces update in the same task

- TASK: 20260720-152519
- BRANCH: feature/work-docs-sync (landed as 05f47a5 via sprout land)
- REVIEW ROUNDS: 1 (out-of-context APPROVE; 1 MINOR + 2 NIT taken at
  discretion)

## What went well

- Smooth two-file text cycle run in parallel with the ledger-lifecycle
  review; no collisions, sequential landings ordered by the sprout land
  sync gate.
- I caught my own case-sensitive DoD grep missing the uppercase sweep
  bullet before closing, and handed the observation to the reviewer to
  judge as a proof-mismatch rather than silently patching it.

## What went wrong

- The DoD proof as planned could not fail against its full criterion (the
  grep survives deletion of the sweep bullet) - the work skill's
  would-it-fail doctrine applies to DoD proofs themselves, not just tests.
- The close-out overclaimed "the last of the seven" while a sibling task
  was still in flight on a parallel branch.

## What to improve next time

- When writing a DoD proof for a two-part criterion, write two proofs (or
  one that spans both conjuncts) and delete-test them mentally.

## Action items

- [x] Ledger: proof-must-cover-its-conjunct added (x1).
