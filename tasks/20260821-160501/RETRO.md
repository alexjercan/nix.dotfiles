# Retro: Internalize agents Home Manager integration

- TASK: 20260821-160501
- BRANCH: scufris-89ec06948b39
- REVIEW ROUNDS: 0

## What went well

- The external integration already separated core, Pi, tools, packages, and
  checks. These boundaries fit below the existing dotfiles module.
- The disabled-module check proves hosts can import the reusable module without
  installing Pi or agent tools.
- Existing consumer-owned instructions and workflow skills did not move.

## What went wrong

- Literal skill subpaths created independent store roots. Cached evaluation
  referenced a root removed by garbage collection.
- `nix fmt` was not available because the flake has no formatter output.

## What to improve next time

- Use `inputs.self` subpaths for reusable source assets from the first edit.
- Check formatter availability before including it in a verification plan.

## Action items

- None.
