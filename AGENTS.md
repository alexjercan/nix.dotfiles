# AGENTS.md

Repo-level guidelines. The global ~/AGENTS.md still applies; this file adds
what is specific to this repository.

## What this repo is

My NixOS and home-manager configuration (flake at the root, hosts under
`hosts/`, home modules under `home/modules/`). It is also the SOURCE of the
agent tooling: the flow-family skills live in `home/modules/agents/skills/`
and the sprout/daily/today CLIs live in `home/modules/scripts/`; the
home-manager module deploys them (the same skills to both `~/.claude/skills`
for Claude Code and `~/.agents/skills` for the codex CLI, and the global
`home/modules/agents/AGENTS.md` to `~/AGENTS.md`).

## Development flow

- `/flow` drives development here: plan/work/review/compound as tatr tasks
  under `tasks/`, each task implemented in a sprout worktree, round-1 reviews
  by an out-of-context reviewer, DoD items with test:/cmd:/manual: proofs.
- `LESSONS.md` at the repo root is the lessons ledger. Read it before
  starting any task; /compound and /lessons maintain it. Records live in
  the task folders (`tasks/<id>/`) and the ledger.
- The conformance gate is `/home/alex/personal/tatr/tatr check` plus
  `/home/alex/personal/tatr/tatr check --ledger LESSONS.md`; both must
  exit 0 (use that binary - the installed tatr may be older).

## Check suite

- `bash home/modules/scripts/sprout-test.sh` - the sprout CLI's test suite.
- `nix flake check --no-build` - flake evaluation.

## Skills are a doc surface

Editing anything the skills describe (sprout behavior, tatr conventions, the
flow itself) invalidates the skill texts in `home/modules/agents/skills/`;
per the docs-sync rule, update those surfaces in the same task, and keep the
skills generic - they run in every repo, not just this one.
