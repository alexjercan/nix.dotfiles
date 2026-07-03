# Add tmux integration and fzf-switch to sprout

- STATUS: OPEN
- PRIORITY: 50
- TAGS: feature

## Goal

Layer tmux workflow integration onto the sprout core: `sprout new` drops you
into a tmux session on the new worktree, a bare `sprout` fzf-picks an existing
worktree to switch to, and `sprout rm` tears down the matching session. This
mirrors how `tmux-sessionizer.nix` (the `sesh` command) creates/switches
sessions.

## Steps

- [ ] In `home/modules/scripts/sprout.nix`, add a helper that opens or switches
      to a tmux session for a given worktree path, reusing the
      tmux-sessionizer logic: session name = `basename | tr . _` (namespace it
      as `<project>_<feature>` to avoid collisions across repos), create
      detached with `tmux new-session -ds` if missing, then `tmux attach` when
      outside `$TMUX` or `tmux switch-client` when inside.
- [ ] Extend `sprout new <feature>` to call that helper after the worktree is
      created, so a successful `new` lands the user in the session.
- [ ] Implement bare `sprout` (no args): `git worktree list`-derived worktrees
      under the sprouts root piped to `fzf`; on selection, open/switch to that
      worktree's session. If nothing selected, print a message and exit 1.
- [ ] Extend `sprout rm <feature>` to `tmux kill-session` for the matching
      session name (ignore errors if the session does not exist) after
      removing the worktree.
- [ ] Add `pkgs.tmux` to `runtimeInputs` (fzf already added in the core task).
- [ ] Verify end to end inside tmux: `sprout new x` opens a session on the
      worktree, bare `sprout` switches between worktrees, `sprout rm x` closes
      the session and removes the worktree.
- [ ] Update the `docs/` note from the core task with the tmux behavior and
      session-naming decision.

## Notes

- Depends on: 20260703-104437 (sprout core must exist first).
- Style reference for all tmux logic: `home/modules/tmux/tmux-sessionizer.nix`
  (session naming with `tr . _`, `pgrep tmux`, `has-session`, `new-session
  -ds`, `attach` vs `switch-client` based on `$TMUX`).
- Namespacing the session as `<project>_<feature>` avoids two repos with a
  `main` feature clashing; document this.
