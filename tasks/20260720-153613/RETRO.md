# Retro: Fix nix flake check 'path ...-hosts is not valid'

- TASK: 20260720-153613
- BRANCH: bug/flake-check-hosts (landed as 68d3ecf via sprout land)
- REVIEW ROUNDS: 1 (out-of-context reviewer: APPROVE)

## What went well

- Reproduced the bug deterministically before touching code, exactly per the
  bug playbook. The intermittent symptom ("fails on master" / "passes now")
  was the tell: fresh eval to populate the flake eval cache, then
  `nix-store --delete` the floating `<hash>-hosts` path, then re-check
  reproduced the exact reported error string. A guessed fix would have been
  unverifiable against an intermittent failure.
- The `f5m9...-hosts` hash in the error was a free oracle: `nix eval` of
  `"${./hosts}"` returned that exact hash, pinning the mechanism (string
  coercion of a path literal creates a floating store root) in one command
  instead of theory.
- The out-of-context reviewer independently re-ran the delete-then-recheck
  repro on both master and the branch, and caught the one real semantic
  subtlety (subpath reflects git-tracked content only, not untracked/dirty
  files) - verified harmless today but worth knowing.
- Fix generalized cleanly: swept `flake/` for other `../` string-coerced
  literals and fixed `home` alongside `hosts` in the same pass, so the whole
  class is gone rather than the one reported instance.

## What went wrong

- The task framing ("stale store path? import-tree + git worktree
  interaction?") pointed at worktrees, and I did spend an early step
  reproducing in a plain `git worktree` (passed) before finding the real
  mechanism. The worktree angle was a red herring; the hash-as-oracle is what
  actually cracked it. Cheap detour, but a reminder to chase the concrete
  artifact (the hash) over the reported hypothesis.
- Landing was blocked by a pre-existing dirty main checkout: a committed task
  file (`tasks/20260703-205034/TASK.md`) was missing from the working tree,
  unrelated to this task and present before it started (the session-start
  snapshot claimed clean). Restored the committed file to land. Surfaced
  rather than silently discarded.

## What to improve next time

- For an intermittent flake/eval failure, reach for the eval-cache + GC-orphan
  hypothesis early: "path X is not valid" on a content-addressed `<hash>-name`
  path almost always means a floating store root the eval cache outlived. The
  fingerprint is the `<hash>-<basename>` shape with no `-source` prefix.
- A pre-land `git status` on the main checkout catches inherited dirt before
  `sprout land` refuses; worth a glance at the start of the land step.

## Lesson for the ledger

- `flake-path-literal-string-coercion`: coercing a `../subdir` path literal to
  a string in a flake (interpolation or `builtins.readDir`) copies it to the
  store as a floating non-GC-root `<hash>-subdir`; GC orphans it against the
  flake eval cache -> "path is not valid". Reference `${inputs.self}/subdir`
  instead so it stays inside the tracked flake source root.
