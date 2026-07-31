# Retro: Write the sabotage-at-plan-time rule into the proofs reference

- TASK: 20260731-125123
- BRANCH: docs/sabotage-proofs-rule
- REVIEW ROUNDS: 2

## What went well

The task made its own rule a plan step, and the rule paid for itself before it
was written: sabotaging the DoD at plan time exposed that two of the three
proofs the task shipped with (`check.sh`, `tatr check --ledger`) were already
green on master. Both were replaced while the plan was still text - one with a
demonstrated budget-overflow mutation, one with a purpose-built `awk` proof for
the ledger fold. That is the second failure mode the new section documents,
caught on the very task documenting it.

Reviewing rounds were cheap because the round-1 reviewer could mutation-test
independently: the proofs are one-line greps over one file, so it re-derived
every falsifiability claim rather than trusting the close-out table.

## What went wrong

Two review rounds, no BLOCKER or MAJOR. The one substantive finding, R1.1, was
a doc surface the diff invalidated: `lessons/ledger.md` states the promoting
task "records the outcome through `tatr ledger`", and folding the entry proved
the CLI has no such flag. The root cause is scoping, not carelessness - the
plan's doc sweep was aimed at `proofs.md` (the file being edited) and the
ledger fold was treated as a mechanical last step rather than as an edit whose
mechanism another skill file describes. A step that hand-edits state a tool is
documented to own always invalidates that documentation.

R2.1 followed from fixing R1.1 under a tight budget: attention went to word
count and the paragraph was left unreflowed, orphaning an article at a line
end. Small, but the ledger already carries `line-breaks-are-load-bearing`.

## What to improve next time

When a step works around a tool's missing capability, grep for the docs that
describe that tool's capability in the SAME step, not in the diff's doc sweep -
the sweep is scoped to the files the change edits, and the workaround by
definition touches a file it does not.

## Action items

- New lesson `workaround-invalidates-the-tool-doc` (x1).
- Bump `line-breaks-are-load-bearing` to x2.
- No follow-up tatr task. The `tatr ledger` CLI gap (no PROMOTE -> PROMOTED
  transition) is now correctly documented as a hand edit; closing it is a CLI
  change in another repository and is left to the user's call rather than
  seeded here.
