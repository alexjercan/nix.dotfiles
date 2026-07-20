# Retro: DoD items name their proof (test/cmd/manual) across plan, work, review, flow

- TASK: 20260720-152457
- BRANCH: feat/dod-proof-notation
- REVIEW ROUNDS: 1 (out-of-context APPROVE)

## What went well

- The out-of-context reviewer earned its keep again: it caught a real
  coherence gap the implementing session missed - the notation said "end each
  item with `(manual: ...)`" but every example led with a bare `manual:`. A
  same-context reviewer would likely have read past it, having written both.
- Defining the notation ONCE authoritatively (plan) and having the other four
  skills reference it kept the diff coherent - the reviewer confirmed uniform
  marker spelling and no rule contradictions across five files.
- Dogfooding was immediate: this task's own DoD and GOAL.md already use the
  notation, so "does it read well" had a concrete artifact to judge.

## What went wrong

- The manual-marker inconsistency shipped into the committed round-1 diff. Root
  cause: I wrote the rule ("ends with its proof") and the examples (leading
  `manual:`) at different moments and never reconciled them - the trailing
  form is natural for test/cmd, the leading form for a pure judgement, and I
  used each where it read best without noticing they contradicted the stated
  rule. Fix was to bless both explicitly rather than force one.

## What to improve next time

- When a skill states a rule AND gives examples, re-read them together as a
  pair before committing - an example that contradicts its own rule is the
  cheapest kind of incoherence to catch and the easiest to miss.

## Handling mid-cycle user feedback

- The user asked mid-round to backtick command proofs so markdown does not
  mangle brace-globs. The branch had not landed and the request was a direct
  refinement of the exact artifact under review (not new scope), so I folded
  it into the round-1 addressing and made backticks part of the prescribed
  notation, rather than deferring it to a new task. Recorded in REVIEW.md's
  round-1 addendum. This is the "finish the cycle in flight" path, not the
  "file a new task" path, because it was small and in-scope.

## Action items

- [x] Fixed R1.1/R1.2 (manual form reconciled) and R1.3 (line wrap) in-round.
- [ ] No follow-up tasks: self-contained docs change.
