# Retro: Update flow skills and afk for tatr v1.0.0 lifecycle

- TASK: 20260802-223038
- BRANCH: chore/tatr-v1-lifecycle
- REVIEW ROUNDS: 1

## What went well

The prerequisite split held. The flake input bump and the 73-record `tatr
migrate` landed on master before the sprout, so the branch was buildable from
its first commit. Review flagged it as a process signal because the branch diff
alone does not show it, but the ordering was the only workable one: v1 tatr
refuses to load a v0 record.

The lifecycle facts were confirmed against tatr 1.0.0 in a scratch repository
at plan time and written into TASK.md as the spec. Review re-derived every one
of them independently and found no drift, so the plan carried the whole edge
semantics and the implementation had nothing left to guess.

One round to APPROVE, no rework. There is no churn to diagnose.

## What went wrong

Rule 8 (`direct-state-edit`) stayed green through the entire v0 regression. It
guarded `flow step` and `plan status` - words nothing in the repository wrote
any more - so a passing check.sh reported a guard that was protecting nothing.
The regression was found by the afk suite going red on `unknown argument: --to`,
not by the rule whose job it was.

Breadth: 16 files. Inherently wide rather than a missed split - a vocabulary
migration across every consumer of one contract, where landing afk without the
skills (or the reverse) leaves the repository half-speaking v1 and rule 8
guarding words the other half still writes. Splitting it would have created a
window with no correct state, not two independently landable changes.

Three skill files (`flow/SKILL.md`, `work/SKILL.md`, `plan/SKILL.md`) broke
their check.sh word budgets on the first pass: v1 needs more vocabulary than v0
to say the same thing. Resolved by compressing rather than raising a budget,
which is the right call, but it is a cost the plan did not anticipate.

## What to improve next time

Value-anchoring rule 8's MARKER was necessary - "activity" and "gates" are
ordinary English where "flow step" was not - but it narrowed the guard, which
review caught as R1.2. The lesson generalizes past this rule: when a lint's
vocabulary changes, the anchor's phrasing variants have to be re-enumerated,
not just its values.

Context: this task crossed a context cut between WORKING and REVIEWING. That
turned out to be free rather than costly - the fresh session was already the
out-of-context reviewer the round-1 default asks for, so no subagent handoff was
needed. Worth planning for deliberately on tasks whose review is substantive.

## Action items

- R1.1 and R1.2 are open MINOR findings, deferred by the APPROVE. Fold them into
  the next touch of `afk-test.sh` and `check.sh` rather than a follow-up task.
- Submitted to the central knowledge repository:
  `verification/a-vocabulary-guard-fails-open` (new), and a `nix.dotfiles`
  occurrence on `changes/re-derive-rules-when-the-model-changes`, which already
  held the tatr-side occurrence of this same migration.
