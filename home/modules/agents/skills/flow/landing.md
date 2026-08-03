# Landing a reviewed branch

Read this only after `compound` closes the task and the LAND_READY gate in
`gates.md` approves landing. Landing is PR-shaped: bring the branch up to date
with its base, re-verify, then squash it back as ONE commit.

## 1. Sync the branch

Merge the landing target into the feature branch, inside its worktree:

```bash
sprout sync <feature> -n   # probe: prints the paths that would conflict
sprout sync <feature>
```

The target is the local branch the sprout was cut from, not `origin/*` - flow
does not push. A conflict is left in the worktree: resolve it there, on the
branch, and commit the merge. Conflict resolution on the default branch is far
harder to unwind.

If the merge turns a test red, run `git show <target>:<path>` on the failing
test FIRST and decide whether this branch caused it or inherited it from a
task that landed in parallel. An inherited red is fixed as merge integration,
naming the source task; do not mis-blame this branch for it.

## 2. Re-verify

Re-run the repository's canonical checks on the updated branch. Proceed only
when green. If the merge changed the work materially, send it back through
`review` before merging.

## 3. Prove the land

Take the subject and body from the committed RETRO.md `## Landing message`
section: `compound` wrote one clean summary of the finished task there. Do not
compose a new one or concatenate the branch messages. Then, from the MAIN
CHECKOUT (never from inside the worktree):

```bash
sprout land <feature> -n -m "<subject>"
```

`-n` runs every guard read-only and writes nothing. It must succeed.

## 4. Inspect, then land

Read the branch diff now, including the committed RETRO.md - once the landing
starts there is no pausing to look. Then, one command:

```bash
sprout land <feature> -m "<subject>" -m "<body>"
```

`sprout land` is atomic: it refuses a dirty main checkout, a detached HEAD, a
call made from inside the worktree, a target the main checkout no longer has
checked out, or a branch not up to date with the target; it squash-merges and
commits, rolling the main checkout back to a clean tree on any failure; then
it removes the worktree, deletes the branch and kills the tmux session.

Do not push; that is the user's call.

## 5. Finish

Under an epic, tick the task in the container TASK.md `## Child Tasks` and
move its open `manual:` DoD items into the container's `## Manual Acceptance`.
Report final verification and usage guidance. End `GOAL DONE <id>`.

## Failure modes

- `sprout land` refuses a dirty main checkout: the dirt is usually a task stub
  or an unrelated edit. Deal with it in the main checkout, then retry; do not
  work around the guard.
- `sprout land` names a target the main checkout is not on: the branch was cut
  from another branch. Check that one out and retry; never land elsewhere.
- The land is its own call from the main checkout, never the tail of a
  worktree command chain - the shell cwd does not persist between calls.
- After landing, gitignored leftovers of a moved or deleted directory survive
  in the main checkout only; clean them by hand.
