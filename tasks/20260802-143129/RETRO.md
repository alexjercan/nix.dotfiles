# Retro: Address the afk runner's round-1 review findings

- TASK: 20260802-143129
- BRANCH: fix/afk-round1-followups
- REVIEW ROUNDS: 2

## What went well

The reopening was diagnosed from evidence rather than guessed. afk's
`WORK_DONE` gate refused a task it read as PLANNED; both the marker and the
cross-check were correct, and the wrong thing was the checkout the transition
wrote. Naming that before fixing anything is why the durable fix landed on the
right layer - the skills' command sites - instead of on `afk.sh`, which was
already behaving correctly by refusing state it could not see.

Every load-bearing claim was falsifiable and got falsified. The
`unrooted-tatr-call` rule shipped with a DoD proof that unroots a real call in
a temp copy and requires the finding to appear, and the review re-derived the
two-line-window claim independently by wrapping `tatr` away from its
subcommand. A doc lint that cannot be shown to fire is indistinguishable from
no lint.

## What went wrong

Breadth: the diff roughly doubled mid-flight. The planned scope was four
review follow-ups on afk's status vocabulary plus a `--repo` note; the
delivered branch also adds a `check.sh` rule and rewrites 25 command sites
across 15 skill files. That second change shares no seam with the first and
was independently landable, so this was a missed split, not an inherently
large feature. It was folded in because the failure surfaced while executing
this task, which is a reason to open a task, not to grow one.

Churn: the one review round of rework traces to a plan-time gap, not to the
implementation. The rooting sweep was a load-bearing design choice - a new
placeholder term propagated to 25 sites - and its rationale lives only in a
`check.sh` header comment and a TASK.md Notes bullet, because DECISION.md was
already spent on the unrelated `AFK_VERBOSE` verdict and the tree is
append-only. `plan/decision.md`'s cold-reader rationale test, applied to the
sweep, asks what `<task-root>` resolves to at each site; that question surfaces
immediately that the term is defined only in `flow/resume.md`, which most
flow-family skills never load, and that its referent changes inside
`work/SKILL.md` step 2. The mechanical half of the fix was enforceable by grep
and got shipped; the half only prose can carry was assumed obvious.

Context: no measured pressure. No compaction warning, no checkpoint, no
delegation. The afk run's failure was a state bug, not a context limit.

## What to improve next time

A lint that checks the SHAPE of a call cannot check its REFERENT. When a sweep
introduces a placeholder that a rule will then require everywhere, the rule and
the prose defining the placeholder's correct value are one change - shipping
only the greppable half converts "the call has no root" into "the call has the
wrong root", which is harder to see and passes the gate.

One record per task is a real constraint on an append-only tree. When a second
load-bearing decision arrives after DECISION.md is spent, a second record for
it belongs to the task that should have been split off, not squeezed into a
header comment.

## Action items

- None open. The `--repo` warning this task was also carrying is landed in
  `compound/SKILL.md`; fixing the `knowledge` skill's own `$PWD` default still
  belongs to the `agent-knowledge` repo and is out of this repo's ownership.
