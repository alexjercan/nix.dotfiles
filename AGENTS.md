# AGENTS.md

Repo-level guidance. Global `~/AGENTS.md` still applies.

## What this repo is

My NixOS and Home Manager configuration. The flake is at the root, hosts are
under `hosts/`, and Home Manager modules are under `home/modules/`.

Agent harnesses, workflow skills, global instructions, afk, sprout, Pi, and
knowledge are owned by the local `~/personal/agents.nix` flake. This repository
imports its optional Home Manager module. Tatr and today remain independent
inputs here. The agent flake follows tatr for afk and its built-in skill; the
today skill is passed through `programs.agents.extraSkills`.

## Agent workflow

- Tracker/epics: tatr records under `tasks/<id>/`; dependencies model
  multi-task goals.
- Examples/retention: verification lives in `flake/` and owning projects; task
  prototypes stay under `tasks/<id>/prototype/`.
- Domain docs: `README.md` plus module comments are the reference.
- Research/network: local sources first; repository checks need no network.
- Checks/records: run `nix flake check` and build the affected configuration;
  records live under `tasks/<id>/`.

## Development workflow

- Prepare tasks with `understand` and `plan`. `afk run <task-id>` accepts only
  a TASK.md with non-empty Steps and Definition of Done.
- `afk` drives work, review, compound, verification, and landing through the
  imported agent workspace. Each task uses one sprout worktree.
- `human:` proofs stay pending and do not block review approval.
- The pinned tatr v2 CLI has no `check` subcommand. Use task-specific proofs;
  do not document or invoke `tatr check`.

## Check suite

- `nix flake check` - evaluate and run this repository's NixOS and Home Manager
  wiring checks. Use the bare command because `--no-build` does not run checks.
- `nix build .#homeConfigurations.alex.activationPackage --no-link` - build the
  standalone Home Manager configuration and all enabled workspace packages.

Agent skill, afk, sprout, and deployment checks run in `agents.nix`, not here.
Today owns its CLI and skill output checks. Tatr owns its tracker and skill.

## Ownership boundaries

- Keep tmux extended keys, Nixvim agent integrations, Node.js, tatr, and today
  in this personal configuration.
- Change agent harnesses, global instructions, workflow skills, afk, sprout, Pi,
  or knowledge in `~/personal/agents.nix` with that repository's checks.
- Changing tatr or today behavior can invalidate their exported skills. Update
  each tool and its skill together in the owning repository.
- The local path inputs are development wiring. Replace them with tagged GitHub
  inputs when the corresponding projects release.
