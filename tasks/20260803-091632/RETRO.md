# Retro: Gate understanding on a NOTES.md scratchpad the user approves

- TASK: 20260803-091632
- BRANCH: feature/understanding-notes-gate
- REVIEW ROUNDS: 3

## What went well

The shared-vocabulary rule in `AGENTS.md` routed the whole implementation: the
`NOTES_READY` grep found every status-list site, and no site had to be
discovered by a failing test.

Round 1 was worth its cost. It found the gate had no teeth under afk - the
other two gates are enforced by `tatr` refusing the transition, but
UNDERSTANDING -> PLANNING is unconditional - and it found the docs sweep had
missed `review/dimensions.md`. Neither was reachable from the checks; both came
from reading the change against the rest of the tree.

## What went wrong

Breadth: the diff is the size the plan said, across nine files. Every file
carries the same status vocabulary, so the change is not separable - splitting
it would land a token half the tree does not recognise. Not a missed split.

Churn: three rounds, and one plan-time question would have prevented most of
them. The plan asked "which files name the new status?" and answered it with a
grep Step. It never asked "which files describe the concept the new status
names?" - so `review/dimensions.md`, which calls NOTES.md a documentation
surface without ever saying `NOTES_READY`, was invisible to the sweep, and
`flow/epic.md`, which describes the activity set, was too. R2.1 is the same
failure one level down: a close-out written before the last commit described a
tree that no longer existed.

Context: no measured pressure. No checkpoint, no compaction warning, no
handoff. All three review rounds ran out of context in subagents, which kept
the implementing session small enough that the whole cycle fit one pass.

## What to improve next time

A doc-surface sweep that greps only the new token finds the files that will
break and misses the files that will lie. When a change introduces a name,
sweep the noun it names as well as the token: `NOTES.md` alongside
`NOTES_READY` would have found R1.1 and R1.3 at plan time.

Write the close-out numbers last, or recompute them at commit time. Any figure
copied into a record before the final commit is a claim about a tree that may
no longer exist - R2.1 caught three.

## Action items

- Submitted centrally as an occurrence on
  `docs/update-restatements-with-the-source`; the lesson already covered it,
  so nothing new was minted and its body is unchanged.
- No follow-up task. R3.1 (the `## Notes` bullet's plan-time budget figures)
  was left open deliberately and is recorded in REVIEW.md.
- The two `Process signal:` bullets from round 1 stay as observations: label
  drift between `gates.md` and `afk.sh` is still caught only by hand-written
  string literals, and the DoD's six-section proof is shape-only. Neither is
  this task's to fix.
