# Associate sprout worktrees with task IDs

- STATUS: CLOSED
- PRIORITY: 50
- TAGS: agents, sprout

## Goal

Associate an optional tatr task ID with each sprout worktree so resume can
identify task ownership directly from `sprout ls`.

## Steps

- [x] Add `sprout new <feature> [--task <ID>]` with syntax validation and
      worktree-local Git config persistence.
- [x] Change `sprout ls` to print BRANCH, TASK, and PATH while preserving
      interactive selection and legacy worktrees without an association.
- [x] Cover creation, persistence, validation, listing, and interactive-facing
      behavior in the integration suite.
- [x] Update sprout and flow/work skill surfaces that describe creation or
      listing.

## Definition of Done

- `sprout new` persists an optional task association and `sprout ls` exposes
  it without changing path-only stdout (test: `bash home/modules/scripts/sprout-test.sh`).
- Skill surfaces agree on creation and the `BRANCH TASK PATH` output
  (cmd: `bash home/modules/agents/skills/check.sh`).
- The repository task records conform (cmd: `tatr check`).
- Changed files contain no whitespace errors (cmd: `git diff --check`).

## Close-out

Implemented the association as `sprout.task` in Git's worktree-local config.
This makes cleanup follow `git worktree remove` and prevents a reused branch
from inheriting stale task metadata. `sprout ls` now prints branch, task and
path; unassociated and detached values use `-`. Interactive selection derives
the feature from the selected path because the feature is no longer a column.

Kept sprout independent from tatr: it validates only the ID shape and does not
require the referenced task to exist. A cache sidecar and branch config were
rejected because both can outlive their worktree association. Integration
tests first failed on the old output, missing validation and absent config,
then passed after implementation.
