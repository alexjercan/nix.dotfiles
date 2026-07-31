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
promotion-stalled lint (tatr check --ledger). That resting state applies
OUTSIDE Pending promotions. Inside it a bare count is not at rest: it is an
unanswered question, and it fails the check as promotion-awaiting-decision
until the user's disposition is recorded.

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

- `verify-first-plan-steps` (x3) -> plan skill: ...
- `wrap-aware-matchers` (x3, DEFER 2026-07-31 at x3: no matcher ships yet): ...
```

## Recording a disposition

An entry under `## Pending promotions` is a question put to the user, and it
carries the user's answer inside its count parens. There are four answers:

- **PROMOTE** - make the change, in a normal reviewed task.
- **DEFER** - not now, with a reason and the count it was taken at.
- **RETIRE** - the lesson's referent is gone; keep it as history.
- **ABSORBED** - a tool or template already made the lesson unnecessary.

`tatr ledger` lists every pending entry with its count and its answer so far;
`tatr ledger -s <slug> -D <disposition>` records one, taking `-t <task-id>` for
a PROMOTE, `-R <reason>` for a DEFER or a RETIRE, and `-T <target>` for an
ABSORBED. The command owns the annotation syntax, the date and the round-trip;
no session composes one of these annotations on its own.

The grammar is validated ONLY under `## Pending promotions`. An entry that was
decided and moved back to its own section keeps the applied marker it already
had - `PROMOTED <date> -> <target>`, `absorbed by <target>, <date>`, or
`RETIRED <date>: <reason>` - so no ledger history is rewritten. Until a
lifecycle event applies, the count stays bare: `(x3)`, never `(x3, note)`.

A recorded disposition is an ANSWER, not a completion. `PROMOTE -> <task-id>`
means a task now owns the change, and the entry stays in Pending until that
task lands; the promoting task's own last step records the outcome through
`tatr ledger`, which is what turns `PROMOTE` into the applied
`PROMOTED <date> -> <target>` and moves the entry back to its section. A
PROMOTE whose task never lands is therefore still visible as pending work,
which is the point.

A DEFER records the count it was taken at, and until the count moves past that
number the answer is cached and not raised again - the same holds for a RETIRE
and an ABSORBED, which is why settling an entry once ends the questioning
rather than deferring it to the next Finish. When the lesson recurs and
`/compound` bumps the count past that number, the deferral no longer covers
the entry and the decision is asked for again. That is the clock-free reason a
DEFER cannot decay into permanent silence.

`tatr check --ledger <file>` reports the four ways this goes wrong:
`promotion-awaiting-decision` (a bare count in Pending, or a DEFER now below
the current count), `bad-disposition` (an annotation matching no form, or
missing its date, reason or target), `dangling-promotion-task` (a PROMOTE
naming a task that does not exist), and `promotion-stalled` (a `(x3)`-or-more
lesson still outside Pending).

## The promotion order

**tool > template/format > skill text.** Ask first whether a CLI guard or a
template change can make the mistake IMPOSSIBLE; only when no tool or template
can hold the rule does it become AGENTS.md or skill prose. Prose warns; tools
prevent. The tatr same-second overwrite recurred seven times under prompt
warnings and died to a four-line CLI guard.

Promotion is proposed, never self-applied. Park the proposal under
`## Pending promotions` so it cannot scroll away inside one retro file, and
let the user decide. A PROMOTE is then a normal tatr task through plan, work,
review and compound, taking the same out-of-context review as any other change
rather than landing as a side effect of the retro that proposed it.

## Shrink-on-absorb

Promotion carries a debt. When a tool or template absorbs a lesson, the skill
prose that lesson had accumulated is DELETED in the same change - or in a
paired change landed alongside it when the tool lives in another repository,
and the absorption is not done until BOTH land. Record the outcome with
`tatr ledger -s <slug> -D ABSORBED -T <tool or template>` once it has.

Skills must shrink as tools harden, or every promotion makes every future
session's context bigger.

## Retirement

A lesson whose referent is gone - the code, tool or workflow it guarded was
deleted or replaced - is neither bumped nor silently dropped. Record it with
`tatr ledger -s <slug> -D RETIRE -R <reason>`, which keeps the lesson's own
sentence intact as history. A release-level pass prunes the entries whose
RETIRED date precedes it, and reports each pruning. Retirement is honest
bookkeeping, not deletion-by-neglect.
