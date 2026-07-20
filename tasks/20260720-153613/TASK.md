# Fix nix flake check: 'path ...-hosts is not valid'

- STATUS: CLOSED
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

## Diagnosis

Not worktree- or import-tree-specific. `flake/nixos-configurations.nix` set
`hostsDir = ../hosts` and `flake/home-configurations.nix` set `homeDir = ../home`.
Coercing those path literals to strings (`"${hostsDir}/${hostName}"` and
`builtins.readDir hostsDir`) copies each directory into the store as its own
floating `<hash>-hosts` / `<hash>-home` root, separate from the flake source.
That root is not a GC root, so `nix-collect-garbage` reaps it while the flake
eval cache still pins the old hash -> a later `nix flake check` fails with
`path '...-hosts' is not valid`. The `f5m9...-hosts` hash in the error is
exactly `"${./hosts}"`.

## Fix

Reference the dirs as subpaths of the flake source: `"${inputs.self}/hosts"`
and `"${inputs.self}/home"`. They then live inside the single flake `-source`
root, which Nix re-copies from the tracked git tree on every eval, so GC can
no longer orphan them.

## Definition of Done

- [x] `nix flake check --no-build` passes on the fixed tree
      (cmd: `nix flake check --no-build`).
- [x] The GC-orphan failure can no longer be set up: fresh eval -> delete the
      referenced store path -> re-check stays green (cmd, deterministic repro:
      run `nix flake check --no-build`, `nix-store --delete` the flake
      `-source` path, re-run `nix flake check --no-build` -> exit 0). On master
      the same sequence against the floating `-hosts` path reproduces the error.
- [x] No other `../` string-coerced directory literals remain in `flake/`
      (cmd: `grep -rn '\.\./' flake/` shows only comment matches).
- [x] The repo-level check suite is `nix flake check --no-build` again (no
      fallback to building a package directly).
