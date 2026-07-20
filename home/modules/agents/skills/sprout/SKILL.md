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
sprout land <feature> -m "<subject>" [-m "<body>"]
                                # squash-merge <feature> into the main
                                # checkout's branch as ONE commit, then rm it
sprout rm <feature>             # remove worktree, force-delete branch, kill tmux session
```

- `new` and `show` print only the worktree path on stdout, so they compose
  with `cd "$(...)"`. `new` reuses the branch if it already exists.
- Branches are cut from the current `HEAD`, so check out the intended base
  branch first if it is not the default. Cutting from local HEAD also makes
  sprout the right isolation when the work depends on unpushed local commits
  (an origin-based worktree would omit them).
- Feature names may contain slashes (`feature/login`) but may not be empty,
  start with `-` or `/`, or contain a `..` segment.
- `ls` shows only this project's worktrees; `<branch>` is `-` on detached
  HEAD. Everything works the same from the main checkout or from inside any
  of its worktrees.
- `rm` uses `git branch -D` (no unmerged protection), so only remove a
  feature you are truly done with. It exits non-zero only when there was
  nothing at all to remove.
- `land` lands the branch as ONE squash commit on whatever branch the main
  checkout has checked out, then does `rm`'s cleanup. It refuses a dirty
  main checkout (tracked changes; untracked are fine), a detached HEAD,
  running from inside the worktree, and a branch that does not contain the
  target's tip - merge the target into the feature and re-verify first. On
  any failure it resets the main checkout so nothing staged is left behind.

## Worktree facts

- A fresh worktree starts with an empty build cache (e.g. `target/`): accept
  the cold build. Never share a build dir (`CARGO_TARGET_DIR`) with the main
  checkout - same crates clobber each other's artifacts, and a worktree
  binary has silently linked the main checkout's code before.
- Gitignored files (caches, autosaves, generated junk) exist only in the main
  checkout. After landing a change that moves or stops shipping a directory,
  clean up its ignored leftovers in the main checkout by hand.

## Rules

- One feature per worktree/branch; do all of that task's work inside its own
  worktree and commit on its branch.
- Sprout is only worktrees and branches; it knows nothing about tasks, plans
  or reviews. "Create a sprout" means exactly that and nothing more. The
  workflow around the worktree lives in `/work` and `/flow`, not here.
