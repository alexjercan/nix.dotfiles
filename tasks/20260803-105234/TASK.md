# Add sprout sync and land --dry-run, remember the target branch, and have compound write the landing message

- PRIORITY: 70
- TAGS: sprout, scripts, skills, afk
- KIND: TASK
- ACTIVITY: PLANNING
- GATES: -
- RESOLUTION: -

Landing is currently three things an agent does by hand from `landing.md`:
merge the target branch into the feature branch, write the squash commit
message, then call `sprout land`. Only the message needs judgement. Move the
mechanical halves into sprout so a runner can drive them, and let `compound`
produce the message while it still has the task in context.

## sprout sync

Add `sprout sync <feature>`: merge the landing target into the feature branch
inside its worktree. This is `landing.md` step 1 as a command.

- `-n`/`--dry-run` probes with `git merge-tree --write-tree <target>
  <feature>`: no index, no worktree, no branch touched. Non-zero plus the
  conflict list when the merge would conflict.
- A conflicting real `sync` leaves the conflict in the worktree for whoever
  called it to resolve; it must not half-land anything in the main checkout.
- Already up to date is success, not an error.

## sprout land -n

Add `-n`/`--dry-run` to `land`, running every guard `cmd_land` already has
read-only: worktree exists, branch exists, not called from inside the
worktree, main checkout is on a symbolic ref, target is not the feature
itself, main checkout has no staged or modified tracked files, and the branch
is an ancestor-complete descendant of the target. Write nothing, exit non-zero
with the same message the real refusal prints.

`land` keeps refusing a branch that is not up to date. Syncing stays a
separate verb: an auto-merge inside `land` would leave a half-merged worktree
behind on conflict, and `land` is documented as atomic.

## Remember the target branch

`sprout new` branches off HEAD and records the task ID with `git config
--worktree sprout.task`. The landing target is currently re-derived at land
time from whatever branch the main checkout happens to have checked out,
which need not be what the branch was cut from. Record it the same way -
`sprout.target` on the worktree config, set at `new` from the main checkout's
current branch - and have `sync` and `land` prefer it, falling back to the
current behaviour when it is absent so existing worktrees keep working.

## compound writes the landing message

The `compound` skill closes the task with full context. Have it also record
the landing commit message - a Conventional Commit subject plus a short body,
one clean summary of the finished task, not the concatenated branch messages -
into the task record, so `sprout land -m` can be called by a script that never
read the diff. Decide where it lives (RETRO.md section or its own record) and
state it in the skill.

## Notes

- `landing.md` step 1 becomes `sprout sync <feature>` for humans too.
- Verification after the merge is deliberately NOT part of this: review
  already proved the branch, and the user checks the default branch after a
  run.
- Cover the new paths in `home/modules/scripts/sprout-test.sh`.
