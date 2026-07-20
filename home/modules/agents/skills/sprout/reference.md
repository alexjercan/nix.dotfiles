# Sprout reference

Detail that agents rarely need. The everyday contract lives in `SKILL.md`;
this file covers the interactive mode and background. See `docs/sprout.md` in
the nix.dotfiles repo for the design rationale; the source is
`home/modules/scripts/sprout.sh` (wrapped by `sprout.nix`, tested by
`sprout-test.sh` next to it).

## Interactive (tmux) mode

The leading `-i`/`--interactive` flag adds tmux integration, mirroring the
`sesh` (tmux-sessionizer) workflow:

- `sprout -i new <feature>` creates the worktree, then opens or switches to a
  tmux session rooted in it.
- `sprout -i ls` runs an `fzf` picker over the worktrees (showing the feature
  and branch columns) and switches to a session on the selection.

Sessions are named `<project>_<feature>`. `sprout rm` always kills the
matching session, with or without `-i`. Without `-i`, `new` and `ls` do no
tmux work and stay safe to use in scripts.

## Where worktrees live

```
${XDG_CACHE_HOME:-$HOME/.cache}/sprouts/<project>/<feature>
```

`<project>` is the basename of the repo's main worktree, resolved from
`git worktree list`, so sprout behaves identically whether it is run from the
main checkout or from inside one of its worktrees. `rm` also prunes empty
parent directories under the cache root after removing a worktree.

## Workflow for parallel agents

1. From the repo, create an isolated worktree per parallel task:
   `sprout new <feature>` (or `-i new` to also drop into a tmux session).
2. Do all of that task's work inside the worktree; commit on its branch.
   Other agents work their own worktrees on their own branches, so nothing
   collides.
3. `sprout ls` to see what is in flight; `sprout show <feature>` to get a
   path to `cd` into.
4. When a branch is ready, `sprout land <feature> -m "<subject>"` squash-
   merges it into the main checkout's branch and cleans everything up; for
   a merged-elsewhere or abandoned branch, `sprout rm <feature>` removes
   the worktree, deletes the branch, and closes its session.
