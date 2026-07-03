# Review: Resolve sprout project from the main worktree, not the current one

- TASK: 20260703-110225
- BRANCH: fix/sprout-project-resolution

## Round 1

- VERDICT: APPROVE

Minimal, correct fix that delivers the Goal. Verified independently:

- The first `worktree` entry of `git worktree list --porcelain` is the main
  worktree from both the main checkout and a linked worktree, so `project` is
  now stable; confirmed `ls` from inside a worktree matches `ls` from the main
  checkout, and `show`/`rm` operate on the right project from inside a
  worktree.
- The not-a-repo guard still fires: git errors to stderr (suppressed), awk
  emits nothing, and the empty-string check exits 1.
- `awk 'substr($0, 10)'` captures the full path (not `$2`), so a repo path
  containing spaces is handled.
- No dangling `repo_root` reference remains; `sprouts_root` and `session_name`
  inherit the corrected `$project`.
- Package builds and passes shellcheck.

No BLOCKER/MAJOR/MINOR/NIT findings. Clean diff, short round.
