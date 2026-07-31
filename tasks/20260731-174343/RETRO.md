# Retro: Plan simple reviewable one-context changes

- TASK: 20260731-174343
- BRANCH: refactor/plan-one-context-changes
- REVIEW ROUNDS: 1

## What went well

Rejecting a new reference. `sizing.md` would have had "shaping or splitting a
task" as its condition, which is every plan - a reference read on every run is
not progressive disclosure, it is the same context cost one file later. The
suite's own `split-files-need-isolated-phases` lesson answered the design
question before it became a preference argument.

Folding the concept budget into the existing simplest-design rule rather than
adding a parallel bullet. The concept budget IS that rule made checkable; two
bullets would have been two names for one idea, which is the defect this whole
Epic is about.

## What went wrong

My doc sweep read `flow/epic.md` as AGREEING with the new sizing rule and
recorded that as a positive finding. The reviewer read the same two files and
saw one rule stated twice in two vocabularies - "reviewable context" against
"understand-build-review context" - inside a context where an epic flow loads
both. I had copied the phrase from `epic.md` deliberately so the surfaces
would "read as one rule", and that is the reasoning that hid it: agreement and
duplication look identical when you are the one who aligned them.

The failed decision was treating a sweep as a contradiction check. A sweep
that only asks "does anything now contradict this?" cannot see a second copy,
and `check.sh`'s `duplicated-paragraph` rule is verbatim-only, so no gate
covers the paraphrased case either.

Second, the budget-driven rewrite silently retired a rule word. Compressing
the simplest-design bullet dropped "Generality" from its enumeration while
`review/dimensions.md` still fails a diff for "generality no Step names" - so
the planner stopped being told to avoid the thing the reviewer still rejects.
This is a further occurrence of `refactor-by-rule-not-by-section`, already in
Pending promotions awaiting exactly this kind of evidence.

Third, `git checkout HEAD --` wiped uncommitted edits before a sabotage run,
for the second time in this Epic.

## What to improve next time

A doc sweep asks two questions, not one: does anything now CONTRADICT this,
and does anything now RESTATE it? The second question finds duplication, and
it is invisible to the verbatim gate.

After a size-driven rewrite, diff the imperative inventory of the paragraph
against the original, word by word.

## Action items

- No follow-up task. The restatement half is a review-sweep concern folded
  into the ledger below, and `refactor-by-rule-not-by-section` is awaiting a
  user disposition in Pending promotions.
