# Retro: Make avoidable complexity block review approval

- TASK: 20260731-142000
- BRANCH: refactor/complexity-blocks-approval
- REVIEW ROUNDS: 1

## What went well

The out-of-context reviewer earned its keep again: five findings, two of which
no in-session reader would have seen. Asked to confirm the fixes, it re-ran
the sabotage itself rather than accepting the coordinator's word that all four
conjuncts were falsifiable, and it independently checked that the Story cited
in the R1.1 response actually exists rather than being invented to close a
finding.

Reviewing the diff by the rule the diff introduces. The new
neighboring-contract sweep found three of its own omissions: `rounds.md`
RETURNS, then `lanes.md` lane returns, then a ragged reflow.

## What went wrong

The DoD proof for Step 1 could never have failed on its Step-1 half. It was
`rg -q 'applicable.*AGENTS.md'` over the review DIRECTORY, and two independent
defects made it blind: the directory scope let `dimensions.md` satisfy it
alone, and the `SKILL.md` clause it was supposed to guard had wrapped across a
line break, so it was never a candidate match at all. The proof was green from
the first commit while half its criterion was undelivered.

The failed decision: one proof for a criterion naming two files, scoped to
their common parent. It seemed sound because the criterion reads as a single
idea ("the active review instructions cover applicable AGENTS.md"), and a
directory grep looked like the robust choice that would survive a file move.
Robust against a move is exactly what made it blind to a deletion.

Second failure, self-inflicted: the sabotage loop restored with
`git checkout HEAD --` while the round-1 fixes were still uncommitted, so it
reverted the fixes instead of the feature and reported three meaningless
passes. The ledger already carries this rule twice
(`commit-before-every-sabotage`, `checkout-head-not-index`); neither was read
before writing the loop.

Third: the close-out reported `SKILL.md` at 336/400 from `wc -w` on the whole
file, while the gate that owns that number strips frontmatter first and
measures 306. The figure was produced by a different rig than the one whose
verdict it quoted.

## What to improve next time

A criterion naming N files needs N scoped conjuncts, sabotage-tested
individually. Directory scope is for existence, never for coverage.

When quoting a gate's measurement, run the gate's own extractor rather than a
plausible equivalent.

## Action items

- Step 8 (finish the `fix-touches-its-neighbours` promotion through the
  lessons workflow) runs after landing, on the default branch.
- No follow-up task: both improvements are ledger lessons, and the promotion
  audit for each is recorded there.
