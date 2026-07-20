# lessons: resolve 3 pending promotions (dod-grep x5, edit-worktree, dry-run-scratch)

- STATUS: CLOSED
- PRIORITY: 50
- TAGS: chore

## Story

As the maintainer, I want the 3 pending promotions (x3+) in this repo's
LESSONS.md resolved, so that the ledger's promotion queue is clear. The
`dod-grep-excludes-task-records` (x5) entry can be marked promoted once the
plan-skill template fix (task #1) ships.

## Steps

- [x] Review the 3 pending lessons (dod-grep-excludes-task-records x5, edit-the-worktree-not-the-cwd x3, dry-run-in-a-scratch-repo x3).
- [x] For each: promote (AGENTS.md / skill / tool) or retire; annotate with the promotion marker.
- [x] Mark dod-grep-excludes-task-records promoted once task #1 lands the template fix.

## Definition of Done

- Every x3+ pending lesson is annotated promoted or retired (cmd: `tatr check --ledger LESSONS.md` clean).

## Notes

- Depends on task #1 (plan-skill DoD-grep template) for the dod-grep entry.
