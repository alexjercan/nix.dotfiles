# Retro: Add sprout sync and land --dry-run, remember the target branch, and have compound write the landing message

- TASK: 20260803-105234
- BRANCH: feature/sprout-sync-land-dry-run
- REVIEW ROUNDS: 2

## What went well

- Planning the `compound/SKILL.md` word-budget trims as part of the step made a
  390-of-400-word squeeze mechanical instead of a redesign; `check.sh` was the
  arbiter throughout.
- `DECISION.md` settled both load-bearing forks (compare-don't-redirect on
  `sprout.target`, RETRO.md section over a new tatr record kind) before any
  code, and review found nothing to argue in the design.
- The step list survived contact intact; only one test's semantics had to
  change (`test_land_uses_recorded_target`, which can only prove the recorded
  target by contrast, since the mismatch guard means it is observable only when
  it differs from the main checkout's branch).

## What went wrong

- Three of fourteen new tests pinned nothing: they passed unmodified against
  master's `sprout.sh`. The failed decision was writing them red-first against
  *absence* - `sync` did not exist, `--dry-run` was an unexpected argument -
  and treating that red as proof. It seemed sound because the tests did fail
  first, so the plan's test-first rule was followed literally. It is not sound
  because "the command does not exist" and "the command misbehaves" produce the
  same exit code.
- R1.3 fixed the catch-all failure reporting on `sync`'s real merge path but
  not on the `-n` probe path, so round 2 re-found the same defect one branch
  over (R2.1, deferred). Fixing a class of defect only at the instance the
  finding named, rather than sweeping the class, cost a review round.
- The corrected Evidence paragraph introduced its own contradiction (R2.2), a
  side effect of editing prose about counts under review pressure.

## What to improve next time

- Breadth: 683 insertions, but not splittable as executed - `sprout.target` is
  what makes `sync` and `land -n` more than wrappers, and the doc surfaces must
  move with the behaviour or `check.sh` fails. Not a missed split.
- Churn: both rounds trace to one plan-time gap. The plan named every new test
  but never what each had to *discriminate against*. The from-scratch challenge
  in `plan` would not have caught it; a per-test "what passes today that this
  must reject" note would have. Running the branch's test file against the base
  implementation is the cheap mechanical version of that check, and belongs at
  write time rather than in review.
- Context: no observed pressure - no compaction warning, no checkpoint, no
  handoff, no delegation.

## Action items

- 20260803-114730 carries the three deferred round-2 findings (R2.1 probe
  failure reporting, R2.2 Evidence wording, R2.3 detached-dry-run assertion).
- Central knowledge bumped, no new slugs: `testing/prove-the-test-can-fail`
  (red against absence is not red against misbehaviour) and
  `changes/fix-the-property-not-the-instance` (R1.3 patched one of the two
  call sites sharing the catch-all).

## Landing message

```
feat: add sprout sync, land --dry-run, and a recorded landing target

sprout gains `sync <feature>`, which merges the landing target into the
branch inside its worktree and probes with `git merge-tree` under `-n`,
and `land -n`, which runs every land guard read-only. `sprout new` now
records the main checkout's branch as `sprout.target`; `sync` and `land`
prefer it and fall back to the checkout's current branch, and `land`
refuses a mismatch rather than redirecting where the squash lands. The
skill docs follow: `landing.md` drives the two commands, and `compound`
writes the landing commit message into RETRO.md so a runner can land
without reading the diff.
```
