# Review: Add tmux integration and fzf-switch to sprout

- TASK: 20260703-104501
- BRANCH: feature/sprout-tmux

## Round 1

- VERDICT: APPROVE

The `-i/--interactive` design is delivered cleanly and matches the amended
plan. Verified independently:

- Package builds and passes shellcheck (flake-nixpkgs package build).
- With an isolated tmux server (`TMUX_TMPDIR`): `sprout -i new feat-a` creates
  the worktree and a `t2work_feat-a` session; `sprout rm feat-a` kills it; a
  slash name folds to `t2work_grp_sub`; `sprout -i ls` without a tty degrades
  to "nothing selected" (exit 1) instead of hanging; non-interactive
  `new`/`ls`/`show` are unchanged and tmux-free.
- The retro lesson from the core task is applied: `open_session` checks
  `tmux new-session`'s result and exits non-zero on failure, while
  has-session/kill-session errors are intentionally tolerated.
- `open_session` correctly runs only after `cmd_new` succeeds (cmd_new `exit`s
  on failure, so a failed `new -i` opens no session), and uses exact-match
  targets (`=name`) to avoid tmux prefix matching.

No BLOCKER/MAJOR/MINOR findings against this diff. One observation, filed as a
follow-up rather than a blocker:

- [ ] R1.1 (NIT) home/modules/scripts/sprout.nix (top-level project
  derivation) - `project`/`sprouts_root` come from `git rev-parse
  --show-toplevel`, which inside a worktree returns that worktree, so running
  sprout from within a sprout worktree resolves the wrong project (confirmed:
  `sprouts/alpha` instead of `sprouts/<repo>`). This is pre-existing core-task
  (20260703-104437) logic surfaced by, not introduced in, this diff, and it is
  relevant to the parallel-agent use case. Filed as its own bug task
  20260703-110225; not blocking this branch.
  - Response:
