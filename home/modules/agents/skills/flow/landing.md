# Landing an approved branch

Read this after `review` returns APPROVE and `compound` has
committed the retro on the feature branch. Landing is PR-shaped: bring the
branch up to date with its base, re-verify, then squash it back as ONE commit.

## 1. Sync the branch

In the WORKTREE, merge the local default branch into the feature branch:

```bash
git -C "$(sprout show <feature>)" merge <default>
```

`<default>` is the local default branch, not `origin/*` - flow does not push.
Resolve conflicts here, on the branch, and commit the merge. Conflict
resolution on the default branch is far harder to unwind.

If the merge turns a test red, run `git show <default>:<path>` on the failing
test FIRST and decide whether this branch caused it or inherited it from a
task that landed in parallel. An inherited red is fixed as merge integration,
naming the source task; do not mis-blame this branch for it.

## 2. Re-verify

Re-run the repository's canonical checks on the updated branch. Proceed only
when green. If the merge changed the work materially, send it back through
`review` before merging.

## 3. Prove it is up to date

```bash
git merge-base --is-ancestor <default> <feature-branch>
```

Must succeed. Only an up-to-date branch may land.

## 4. Inspect, then land

Read the branch diff now, including the committed RETRO.md - once the landing
starts there is no pausing to look. Then, from the MAIN CHECKOUT (never from
inside the worktree), one command:

```bash
sprout land <feature> -m "<subject>" -m "<body>"
```

`sprout land` is atomic: it refuses a dirty main checkout, a detached HEAD, a
call made from inside the worktree, or a branch not up to date with the
target; it squash-merges and commits, rolling the main checkout back to a
clean tree on any failure; then it removes the worktree, deletes the branch
and kills the tmux session.

Write one clean summary of the finished task - a Conventional-Commit subject
plus a short body - not the concatenated branch messages. Do not push; that is
the user's call.

## 5. Close out

`tatr flow <id>` to DONE before landing (it closes the task, and the closing
edit belongs in the squash commit). Under an epic, also tick the task in the
container TASK.md `## Child Tasks` and move its open `manual:` DoD items into
the container's `## Manual Acceptance`.

Report one line ending with `DONE <id>`.

## Failure modes

- `sprout land` refuses a dirty main checkout: the dirt is usually a task stub
  or an unrelated edit. Deal with it in the main checkout, then retry; do not
  work around the guard.
- The land is its own call from the main checkout, never the tail of a
  worktree command chain - the shell cwd does not persist between calls.
- After landing, gitignored leftovers of a moved or deleted directory survive
  in the main checkout only; clean them by hand.
