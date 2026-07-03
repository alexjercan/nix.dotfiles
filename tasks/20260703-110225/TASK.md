# Resolve sprout project from the main worktree, not the current one

- STATUS: OPEN
- PRIORITY: 50
- TAGS: bug

## Goal

`sprout` derives `project` (and thus `sprouts_root`) from
`git rev-parse --show-toplevel`, which inside a worktree returns that
worktree's own path. So running `sprout ls`/`rm`/`new` from within a sprout
worktree computes the wrong project (e.g. `sprouts/alpha` instead of
`sprouts/<repo>`) and operates on the wrong tree. Since the whole point is
parallel agents each working inside their own worktree, sprout must resolve a
stable project identity no matter which worktree it runs from.

## Steps

- [ ] In `home/modules/scripts/sprout.nix`, replace the `repo_root=$(git
      rev-parse --show-toplevel)` / `project=$(basename ...)` derivation with
      one anchored to the main worktree. Options: use `git rev-parse
      --git-common-dir` (points at the main repo's `.git`) and take the
      basename of its parent, or take the first entry of `git worktree list
      --porcelain` (the main worktree). Pick whichever is robust for both a
      normal checkout and a linked worktree.
- [ ] Verify `sprout ls` from inside a worktree lists the same worktrees as
      from the main checkout, and `project` is identical in both contexts.
- [ ] Update `docs/sprout.md` if the project-resolution rule is worth stating.

## Notes

- Surfaced during review of 20260703-104501 (tmux integration); the root cause
  is in the core task 20260703-104437's project derivation, so it is filed as
  its own bug rather than blocking the tmux branch.
- Relevant file: home/modules/scripts/sprout.nix (top-level `repo_root` /
  `project` / `sprouts_root` block, and `session_name` which also uses
  `$project`).
