# Add tmux integration and fzf-switch to sprout

- STATUS: OPEN
- PRIORITY: 50
- TAGS: feature

## Goal

Layer tmux workflow integration onto the sprout core, gated behind an
`-i, --interactive` flag so the default behavior stays script-friendly
(prints paths, no tmux). With `-i`:

- `sprout -i new <feature>` creates the worktree/branch, then opens or
  switches to a tmux session on it.
- `sprout -i ls` runs an `fzf` picker over the project's worktrees and opens
  or switches to a tmux session on the selected one.

Without `-i`, `new` and `ls` behave exactly as the core task built them.
`sprout rm` always tears down the matching tmux session if one exists (no flag
needed). This mirrors how `tmux-sessionizer.nix` (the `sesh` command)
creates/switches sessions.

## Steps

- [ ] Parse a global `-i, --interactive` flag in the argument dispatch: accept
      it either before the subcommand (`sprout -i new x`) or as the first
      token, set an `interactive` boolean, and leave the remaining args for the
      subcommand. Keep the existing non-interactive paths unchanged.
- [ ] In `home/modules/scripts/sprout.nix`, add a helper `open_session <path>`
      that opens or switches to a tmux session for a worktree path, reusing the
      tmux-sessionizer logic: session name = `<project>_<feature>` run through
      `tr . _` (namespaced by project to avoid cross-repo collisions); if no
      tmux server is running start one with `tmux new-session`, else create it
      detached with `tmux new-session -ds` when `has-session` is false, then
      `tmux attach` when outside `$TMUX` or `tmux switch-client` when inside.
- [ ] Extend `cmd_new` so that when `interactive` is set it calls
      `open_session` on the new worktree after creation (still prints the path
      first). Non-interactive `new` is unchanged.
- [ ] Extend `cmd_ls` so that when `interactive` is set it pipes the worktree
      list to `fzf` (feature + branch + path columns, selection resolved back
      to a path) and calls `open_session` on the pick; if nothing is selected,
      print a message and exit 1. Non-interactive `ls` still prints the table.
- [ ] Extend `cmd_rm` to `tmux kill-session -t <project>_<feature>` after
      removing the worktree, ignoring errors when the session does not exist.
- [ ] Add `pkgs.tmux` to `runtimeInputs` (git and fzf are already there from
      the core task).
- [ ] Update `sprout help` to document the `-i, --interactive` flag and its
      effect on `new` and `ls`.
- [ ] Verify: the package still builds (shellcheck passes) via the
      flake-nixpkgs `nix build --impure --expr` used in the core task, and
      exercise inside tmux that `sprout -i new x` opens a session, `sprout -i
      ls` fzf-switches, `sprout rm x` closes the session, and the plain
      `sprout new/ls` paths are untouched.
- [ ] Update `docs/sprout.md` with the `-i` flag, the fzf/tmux behavior, and
      the session-naming decision.

## Notes

- Depends on: 20260703-104437 (sprout core; CLOSED).
- Amendment (2026-07-03): the user asked for an `-i, --interactive` flag rather
  than always opening a session on `new` / using a bare `sprout` for fzf. So
  the flag gates tmux behavior for `new` and `ls`; there is no bare-`sprout`
  fzf switch anymore (bare `sprout` still prints usage).
- Style reference for all tmux logic: `home/modules/tmux/tmux-sessionizer.nix`
  (session naming with `tr . _`, `pgrep tmux`, `has-session`, `new-session
  -ds`, `attach` vs `switch-client` based on `$TMUX`). fzf is already a
  runtime input and is used by the interactive `ls`.
- Namespacing the session as `<project>_<feature>` avoids two repos with a
  `main` feature clashing; document this.
