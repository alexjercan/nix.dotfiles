# Fix nix flake check: 'path ...-hosts is not valid'

- STATUS: OPEN
- PRIORITY: 60
- TAGS: bug

## Goal

`nix flake check --no-build` fails on master with:

    error: path 'f5m9dpxnrvcdm93bml965cii0ikmlzr0-hosts' is not valid

Pre-existing (reproduced on the untouched master checkout on 2026-07-20,
unrelated to the flow-suite v2 work); discovered while verifying the
sprout-land task, which fell back to building the sprout package directly.
Diagnose (stale store path? import-tree + git worktree interaction?) and
restore a working repo-level check, then re-point the check suite at it.
