---
name: sprout
description: Manage git worktrees with the sprout CLI so several agents can work the same repository in parallel without colliding. Use when work should happen on an isolated worktree and branch, or when the user mentions sprout, worktrees, or parallel branches. Not needed during /work or /flow - those skills already embed the sprout commands they use.
---

# Sprout - Git Worktrees for Parallel Work

Small CLI that creates and removes git worktrees plus their branches, one per
feature, under `${XDG_CACHE_HOME:-$HOME/.cache}/sprouts/<project>/<feature>`.
For interactive tmux mode and design background, read `reference.md` in this
skill's directory; `sprout help` prints usage.

## Commands

```bash
cd "$(sprout new <feature>)"    # create worktree + branch <feature> off HEAD
cd "$(sprout show <feature>)"   # print path of an existing worktree
sprout ls                       # one line per worktree: <feature> <branch> <path>
sprout rm <feature>             # remove worktree, force-delete branch, kill tmux session
```

- `new` and `show` print only the worktree path on stdout, so they compose
  with `cd "$(...)"`. `new` reuses the branch if it already exists.
- Branches are cut from the current `HEAD`, so check out the intended base
  branch first if it is not the default.
- Feature names may contain slashes (`feature/login`) but may not be empty,
  start with `-` or `/`, or contain a `..` segment.
- `ls` shows only this project's worktrees; `<branch>` is `-` on detached
  HEAD. Everything works the same from the main checkout or from inside any
  of its worktrees.
- `rm` uses `git branch -D` (no unmerged protection), so only remove a
  feature you are truly done with. It exits non-zero only when there was
  nothing at all to remove.

## Rules

- One feature per worktree/branch; do all of that task's work inside its own
  worktree and commit on its branch.
- Sprout is only worktrees and branches; it knows nothing about tasks, plans
  or reviews. "Create a sprout" means exactly that and nothing more. The
  workflow around the worktree lives in `/work` and `/flow`, not here.
