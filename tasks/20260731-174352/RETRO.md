# Retro: Make fresh-session handoff a flow contract

- TASK: 20260731-174352
- BRANCH: feat/fresh-session-handoff
- REVIEW ROUNDS: 2

## What went well

Stopping on the budget rather than shaving it. `flow/SKILL.md` was at exactly
300/300 and the obvious fix - a Route row - cost 18 words against about 4 that
could be freed without retiring a rule. Measuring first turned a design
argument into a decision with numbers in it, and the two alternatives (raise
the cap, or merge two routing rows) were both real options with stated costs
rather than strawmen. The record is `DECISION.md`.

`check.sh`'s `direct-state-edit` rule earned its keep: it rejected the first
draft's "leave the task at its current FLOW STEP", which reads as ordering a
lifecycle marker written by hand. The rewrite says what was actually meant - a
checkpoint is not a lifecycle transition, so it runs no `tatr flow`.

## What went wrong

The de-duplication was half a fix, and I recorded it as a whole one. Finding
that `work/delegation.md` already described the checkpoint handoff, I shrank
that section to a three-line stub pointing at `flow/resume.md` and wrote in
the close-out that the duplication was removed. Round 1 showed the stub was
worse than the duplication: it made the checkpoint a two-hop load, so an agent
at a checkpoint read about 990 words across two references to run one
protocol, and the stub still restated `resume.md`'s rules in a second
vocabulary anyway.

The failed decision was treating "make the duplicate smaller" as the same
thing as "give the rule one owner". Shrinking felt safer than deleting because
deleting looked like removing content from a file another Story had just
shipped. But a pointer stub is not a smaller duplicate - it is a duplicate
plus an extra hop.

Worse, `check.sh` passed it. `reference-too-deep` only fires when the nested
target sits in the SAME skill directory, so a cross-skill chain clears the
gate while breaking the convention `README.md` states. The gate proved shape,
not the property I assumed it proved.

Separately, the DECISION.md arithmetic was wrong: I wrote that a 3-word
addition was paid for by 4 words of tightening and implied a 299-word body.
There were three one-word cuts, so the trade is net zero at 300. That number
had also reached the question put to the user.

## What to improve next time

De-duplication has one correct shape: delete the copy and let one file own the
rule, reached from an always-loaded line. If the deletion feels unsafe, the
reason is worth stating, not routing around with a stub.

A green gate licenses only what the gate actually inspects. Before citing
`check.sh` as evidence a structural convention holds, read the rule.

## Action items

- 20260731-204959 seeded: widen `reference-too-deep` to cross-skill pointer
  chains, with a case asserting the gate stays clean on the descriptive
  cross-references already in the tree.
