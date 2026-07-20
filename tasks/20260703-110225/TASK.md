# Resolve sprout project from the main worktree, not the current one

- STATUS: CLOSED
- PRIORITY: 50
- TAGS: bug,historical

## Goal

`sprout` derives `project` (and thus `sprouts_root`) from
`git rev-parse --show-toplevel`, which inside a worktree returns that
worktree's own path. So running `sprout ls`/`rm`/`new` from within a sprout
worktree computes the wrong project (e.g. `sprouts/alpha` instead of
`sprouts/<repo>`) and operates on the wrong tree. Since the whole point is
parallel agents each working inside their own worktree, sprout must resolve a
stable project identity no matter which worktree it runs from.

## Steps

- [x] In `home/modules/scripts/sprout.nix`, replace the `repo_root=$(git
      rev-parse --show-toplevel)` / `project=$(basename ...)` derivation with
      one anchored to the main worktree. Options: use `git rev-parse
      --git-common-dir` (points at the main repo's `.git`) and take the
      basename of its parent, or take the first entry of `git worktree list
      --porcelain` (the main worktree). Pick whichever is robust for both a
      normal checkout and a linked worktree.
- [x] Verify `sprout ls` from inside a worktree lists the same worktrees as
      from the main checkout, and `project` is identical in both contexts.
- [x] Update `docs/sprout.md` if the project-resolution rule is worth stating.

## Notes

- Surfaced during review of 20260703-104501 (tmux integration); the root cause
  is in the core task 20260703-104437's project derivation, so it is filed as
  its own bug rather than blocking the tmux branch.
- Relevant file: home/modules/scripts/sprout.nix (top-level `repo_root` /
  `project` / `sprouts_root` block, and `session_name` which also uses
  `$project`).

## Record

**What changed.** Replaced the `project` derivation in
`home/modules/scripts/sprout.nix`: instead of
`basename "$(git rev-parse --show-toplevel)"` (which returns the current
worktree inside a linked worktree), `project` is now the basename of the main
worktree, taken from the first `worktree` entry of `git worktree list
--porcelain`. `sprouts_root` and `session_name` inherit the fix since they
build on `$project`. Documented the resolution rule in `docs/sprout.md`.

**Decisions / alternatives.** Considered `git rev-parse --path-format=absolute
--git-common-dir` and `basename(dirname(...))`; both give the same result for
a standard layout. Chose the `git worktree list` first-entry approach because
it names the main worktree directly and stays correct even when the common
git dir lives outside the repo (separate gitdir). Kept the not-a-git-repo
guard: the awk pipeline prints nothing when git errors, so the empty-string
check still fires (verified).

**Testing.** Built via the flake-nixpkgs package build (shellcheck). In a
scratch repo with worktrees `alpha` and `beta`, confirmed `ls` from inside
`alpha` matches `ls` from the main checkout, and `show beta` / `rm beta` run
correctly from inside `alpha`. Confirmed the not-a-repo guard still exits 1.

**Self-reflection.** This is exactly the class of bug the core-task retro
warned about (too-narrow test inputs): the original `--show-toplevel` choice
was only ever exercised from the main checkout. Testing a command from the
place it will actually be used (inside a worktree, where the parallel agents
live) is what the review did and what `/work` should have done originally.
