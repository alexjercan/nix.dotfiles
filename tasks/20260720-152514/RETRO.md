# Retro: Ledger lifecycle: RETIRED marker, promotion order, shrink-on-absorb

- TASK: 20260720-152514
- BRANCH: feature/ledger-lifecycle (landed as d356522 via sprout land)
- REVIEW ROUNDS: 1 (out-of-context APPROVE; 4 MINOR + 2 NIT taken at
  discretion in the same branch)

## What went well

- First APPROVE-in-round-1 of this flow, and it was earned, not soft: the
  reviewer verified the lint-exemption design against the real binary with
  the exact annotation forms before approving.
- Reusing the annotation mechanism for all three lifecycle states
  (PROMOTED/absorbed/RETIRED) meant zero tool changes; the 152508
  bare-counts convention paid for itself one task later.
- The discretionary-findings path worked as the skill intends: APPROVE
  with open MINORs, fixes applied from the reviewer's own wordings,
  recorded transparently in REVIEW.md without a rubber-stamp round 2.

## What went wrong

- The first RETIRED example modeled meta-commentary in place of the
  lesson's sentence - the exact history-destruction the rule forbids
  (rule-and-example-must-agree, second occurrence). Root cause: writing
  the example to demonstrate the marker instead of a plausible entry.
- Pruning was described passively with no acting step; a lifecycle without
  an actor is shelf-ware (caught by the reviewer, not me).

## What to improve next time

- When adding a lifecycle state, write its actor and reporting step in the
  same edit as its definition.

## Action items

- [x] Ledger: rule-and-example-must-agree bumped to x2.
