# Retro: PR-style branch sync before squash-merge

- TASK: 20260704-134842
- BRANCH: feature/pr-style-branch-sync (squash-merged into flow-pr-squash-merge)
- REVIEW ROUNDS: 1 (APPROVE)

See `tasks/20260704-134842/{TASK,REVIEW}.md`. Process notes only.

## What went well

- Dry-ran the whole git sequence in a scratch repo before writing a single
  instruction: merge default into the branch, `merge-base --is-ancestor` gate,
  then `git merge --squash` on the default branch. That confirmed the load-
  bearing claim ("the squash applies cleanly because the branch already
  contains the default tip") is literally true rather than plausible, and that
  `git branch -D` still works afterward. Same "ground truth beats reasoning"
  move the prior squash-merge retro pushed for, and it paid off again.
- Split the change by ownership, not by file convenience: `/flow` owns the
  land-sequence, `/work` owns running checks in the worktree, so the sync-and-
  re-verify mechanics went into `/work` and the ordering/gate went into
  `/flow`. Each skill reads correctly on its own, and standalone `/work` did
  not gain a false "you must merge" behavior.
- Dogfooded the new step 5 to actually land this task (merge default in, gate
  on `--is-ancestor`, squash-merge back, `sprout rm`). The instructions are
  executable because they were executed.

## What went wrong

- Sprouted the task worktree before committing the plan onto the integration
  branch, so the first sub-sprout did not contain `tasks/<id>/TASK.md`. Had to
  `sprout rm`, commit the plan, and re-sprout. Root cause: ran `sprout new`
  reflexively as the "opening move" before the plan artifact was on the branch
  it would be cut from.

## What to improve next time

- When nesting a `/flow` run inside a `/sprout` container branch, commit the
  plan (the TASK.md files) onto the integration branch *before* sprouting the
  first task worktree, so the task travels into the sub-worktree from the
  start. More generally: a sprout inherits only what is committed on HEAD, so
  commit anything the task needs before cutting it.

## Action items

- [x] Confirmed no stale references to the old single-step squash flow in the
      other skills / README (grep clean); `/review` three-dot diff still shows
      only task changes after the sync, so no review-skill change was needed.
- [ ] Watch the first real multi-task `/flow` run where the default branch
      actually moves under a task: confirm the agent runs the sync merge and
      the `merge-base --is-ancestor` gate rather than skipping straight to the
      squash out of habit. If it slips, tighten step 5's wording.
