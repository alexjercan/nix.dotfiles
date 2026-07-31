# The lessons ledger

## Location and format

Use root `LESSONS.md`, else `docs/LESSONS.md`. If both exist, use root and
flag the duplicate. If neither exists, create beside durable project docs.

Each lesson: slug, one sentence, `(xN)`, and one/two task IDs, under Process,
Domain, or Pending promotions. Counts stay bare until a lifecycle annotation.
At x3 move unanswered entries to Pending; bare counts there fail
`tatr check --ledger`.

```markdown
## Process lessons
## Domain lessons (project-specific)
## Pending promotions (3+ occurrences, user decides)
```

## Dispositions

Only the user chooses:

- PROMOTE: normal reviewed task.
- DEFER: reason, cached at current count.
- RETIRE: referent gone; retain history until release pruning.
- ABSORBED: named tool/template already prevents it.

List/record through `tatr ledger`; it owns dates and syntax. PROMOTE requires
task ID, DEFER/RETIRE a reason, ABSORBED a target. Never compose disposition
annotations by hand.

A PROMOTE remains Pending until its task lands. The promoting task then
hand-edits the entry back to its section with
`PROMOTED <date> -> <target>`. `tatr ledger` records the disposition only; it
has no completion-transition command. DEFER becomes unanswered when count
exceeds its recorded count; RETIRE/ABSORBED stay settled.

Ledger lint reports unanswered/expired decisions, bad annotations, dangling
promotion tasks, and x3 entries outside Pending.

## Promotion order

`tool > template/format > skill prose`: prevent before warning. Compound only
proposes; user decides; promoted work uses normal plan/work/review/compound.

When a tool/template absorbs a rule, delete accumulated skill prose in the
same or paired cross-repo change. Absorption is complete only when both land.

Retire only when the guarded referent disappeared. Record through
`tatr ledger ... -D RETIRE`; release-level lessons passes prune entries older
than the release and report them.
