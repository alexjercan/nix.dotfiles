# Retro: Add explicit flow dispatch table

- TASK: 20260731-142934
- BRANCH: feat/flow-dispatch-table
- REVIEW ROUNDS: 2

## What went well

The two-part DoD grep was sabotaged per conjunct before the branch was
handed over: rewriting the header row reddens only the first clause, deleting
the spike row only the second. Neither could have shipped as an unfalsifiable
proof. Both greps were also run against master first, so the change had a
red baseline rather than a claim of one.

`check.sh` behaved as a real gate rather than a formality. It rejected seven
successive drafts on the router word budget, which is what forced the design
question - what does the table have to say, and what already lives in a
pointer condition - instead of letting a comfortable draft through.

The out-of-context reviewer found the one defect the implementing session
could not: the legend describing the tool's own transition semantics was
false. Round 2 then caught a residual imprecision in the close-out.

## What went wrong

The round-1 MAJOR: the legend read "`--to` marks a non-default edge". That
generalisation came from reading `tatr/lifecycle.md`'s prose about the fix
loop, not from running `tatr flow`. A bare `tatr flow` in fact performs
PLANNING -> PLANNED and PLANNED -> WORKING, so the table taught a wrong
transition graph while its own Step 4 ("remove conflicting route prose") was
ticked. The decision seemed sound because `--to` genuinely IS required for the
one backward edge and is the form every phase skill spells out; the error was
promoting "the form we always write" into "the form the tool requires".

Compression under the 300-word budget silently retired four rule words across
the two rounds - `version` from the epic pointer, `landing` from the landing
pointer, `last` from the status-line contract, and `one` from "one task".
Every one of them was caught by review, none by the author. The trims felt
lossless one at a time because each was judged against the sentence it sat in
rather than against the rule it carried.

## What to improve next time

A sentence that summarises a tool's behaviour is a testable claim, and a
legend above a routing table is exactly that. Run the tool, in a scratch
repository if need be, before writing the generalisation - the probe here took
two commands and would have prevented the round.

Before trimming to a size budget, take an inventory of the imperative words
the text carries, and diff that inventory - not the prose - after the trim.
Reading the trimmed sentence back only proves it still reads well.

## Action items

- None requiring a new task. Both lessons are ledger entries; the promotion
  question for `refactor-by-rule-not-by-section`, now at three occurrences,
  belongs to `lessons` and the user, not to this retro.
