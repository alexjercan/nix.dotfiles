# The lessons ledger

## Where it lives

Search in order: `<repo-root>/LESSONS.md`, then `<repo-root>/docs/LESSONS.md`.
Use whichever exists. If BOTH exist, prefer the root one and flag the
duplicate to the user. If neither exists, create `LESSONS.md` at the repository
root - or beside the project's other durable docs if that is where they live.

## Format

```markdown
# Lessons ledger

One or two lines per lesson: slug, one sentence, an occurrence count, and a
task id or two. /compound and /lessons append new lessons or bump counts; two
lines is the cap. At three occurrences a lesson moves to Pending promotions.
Counts stay bare - (xN) - until a lifecycle event annotates them; the
annotation is the lifecycle marker and exempts the entry from the
promotion-stalled lint (tatr check --ledger).

## Process lessons

- `diagnostic-first` (x4): trace the exact reported scenario before theorizing
  a mechanism. 20260709-125640, 20260711-103527
- `same-second-ids` (x7, absorbed by tatr new collision guard, 2026-07-18):
  chained tatr new calls overwrote tasks; the CLI now fails instead. ...
- `stale-harness` (x2, RETIRED 2026-07-16: env-gated harness replaced by the
  dev/harness plugin): rebuild before trusting env-gated behavior. ...

## Domain lessons (project-specific)

- `two-clocks` (family): FixedUpdate reads raw state, render-rate reads eased
  state; one computation, one clock, one frame. ...

## Pending promotions (3+ occurrences, user decides)

- `verify-first-plan-steps` -> plan skill: ...
```

## Count annotations

The parenthesized annotation IS the lifecycle marker, and an annotated count
is invisible to `promotion-stalled` by design. The three forms:

- `(xN, PROMOTED <date> -> <target>)`
- `(xN, absorbed by <tool or template>, <date>)`
- `(xN, RETIRED <date>: <one-line reason>)`

Until one of those applies, the count stays bare: `(x3)`, never `(x3, note)`.

## The promotion order

**tool > template/format > skill text.** Ask first whether a CLI guard or a
template change can make the mistake IMPOSSIBLE; only when no tool or template
can hold the rule does it become AGENTS.md or skill prose. Prose warns; tools
prevent. The tatr same-second overwrite recurred seven times under prompt
warnings and died to a four-line CLI guard.

Promotion is proposed, never self-applied. Park the proposal under
`## Pending promotions` so it cannot scroll away inside one retro file, and
let the user decide. An approved promotion is then a normal tatr task through
plan, work, review and compound.

## Shrink-on-absorb

Promotion carries a debt. When a tool or template absorbs a lesson, the skill
prose that lesson had accumulated is DELETED in the same change - or in a
paired change landed alongside it when the tool lives in another repository,
and the absorption is not done until BOTH land. The entry's annotation then
becomes `(xN, absorbed by <tool or template>, <date>)`.

Skills must shrink as tools harden, or every promotion makes every future
session's context bigger.

## Retirement

A lesson whose referent is gone - the code, tool or workflow it guarded was
deleted or replaced - is neither bumped nor silently dropped. Mark it
`(xN, RETIRED <date>: <reason>)`, keeping the lesson's own sentence intact as
history. A release-level pass prunes the entries whose RETIRED date precedes
it, and reports each pruning. Retirement is honest bookkeeping, not
deletion-by-neglect.
