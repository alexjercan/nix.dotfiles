---
name: sprout
description: Manage git worktrees with the sprout CLI so several agents can work the same repository in parallel without colliding. Use this skill whenever work should happen on an isolated worktree and branch - starting a feature while another is in flight, running multiple agents against one repo at once, or spinning up a throwaway checkout - and whenever the user mentions sprout, worktrees, or parallel branches. Each feature gets its own worktree and branch under a hidden cache root.
---

# Sprout - Git Worktrees for Parallel Work

Sprout is a small CLI that creates and tears down git worktrees plus their
branches, so several agents (or several tasks) can work the same repository at
the same time without stepping on each other. Each feature gets an isolated
worktree and branch, checked out in its own directory outside the repo. See
`docs/sprout.md` in the nix.dotfiles repo for the design rationale; the source
is `home/modules/scripts/sprout.nix`.

## Commands

```bash
sprout [-i] new <feature>   # Create a worktree + branch <feature> off HEAD
sprout [-i] ls              # List this project's worktrees
sprout show <feature>       # Print the path to <feature>'s worktree
sprout rm <feature>         # Remove <feature>'s worktree, branch and session
sprout help                 # Show usage
```

- `new` branches off the current `HEAD` and creates the worktree. If the branch
  already exists it is reused. On success the only thing printed to stdout is
  the worktree path, so it composes: `cd "$(sprout new feat)"`.
- `show` prints only the path too, so `cd "$(sprout show feat)"` works.
- `rm` removes the worktree (forcing if it is dirty), deletes the branch with
  `git branch -D`, kills the matching tmux session, and prunes empty parent
  dirs. It exits non-zero only when there was nothing at all to remove.

Feature names may contain slashes (`feature/login`) but may not be empty, start
with `-` or `/`, or contain a `..` segment.

## Where worktrees live

```
${XDG_CACHE_HOME:-$HOME/.cache}/sprouts/<project>/<feature>
```

`<project>` is the basename of the repo's main worktree, resolved from
`git worktree list`, so sprout behaves identically whether it is run from the
main checkout or from inside one of its worktrees. An agent working inside
`sprouts/<project>/<feature>` can still run `sprout ls`/`rm`/`show` and see the
whole project's worktrees.

## `sprout ls` output

One line per worktree, three whitespace-separated columns, no header:

```
<feature>   <branch>   <path>
```

- `<feature>` - the name passed to `sprout new` (the argument `show`/`rm` take).
- `<branch>` - the branch in that worktree, or `-` if detached HEAD.
- `<path>` - the absolute worktree path.

Only this project's worktrees are listed.

## Interactive (tmux) mode

The leading `-i`/`--interactive` flag adds tmux integration, mirroring the
`sesh` (tmux-sessionizer) workflow:

- `sprout -i new <feature>` creates the worktree, then opens or switches to a
  tmux session rooted in it.
- `sprout -i ls` runs an `fzf` picker over the worktrees (showing the feature
  and branch columns) and switches to a session on the selection.

Sessions are named `<project>_<feature>`. `sprout rm` always kills the matching
session, with or without `-i`. Without `-i`, `new` and `ls` do no tmux work and
stay safe to use in scripts.

## Workflow for parallel agents

1. From the repo, create an isolated worktree per parallel task:
   `sprout new <feature>` (or `-i new` to also drop into a tmux session).
2. Do all of that task's work inside the worktree; commit on its branch. Other
   agents work their own worktrees on their own branches, so nothing collides.
3. `sprout ls` to see what is in flight; `sprout show <feature>` to get a path
   to `cd` into.
4. When a branch is merged (or abandoned), `sprout rm <feature>` to remove the
   worktree, delete the branch, and close its session.

## Guidelines

- One feature per worktree/branch; do not do unrelated work in someone else's
  worktree.
- Branches are cut from whatever `HEAD` is when you run `new`, so check out the
  intended base branch first if it is not the default.
- `rm` uses `git branch -D` (force): it does not protect unmerged branches, so
  only remove a feature you are truly done with.
