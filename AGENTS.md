# AGENTS.md

Repository guidance. Global `~/AGENTS.md` applies.

## Project

- NixOS and Home Manager configuration. Flake at the root.
- Hosts: `hosts/`. Home modules: `home/modules/`.
- `agents.nix` owns harnesses, skills, global instructions, afk, sprout, Pi,
  and knowledge. Tatr and today remain independent inputs.

## Agent workflow

- Tracker/epics: tatr records under `tasks/<id>/`; dependencies model
  multi-task goals.
- Examples/retention: verification belongs in `flake/` or the owning project;
  task prototypes stay with the task.
- Domain docs: `README.md` and module comments are authoritative.
- Research/network: use local sources first; repository checks need no network.
- Checks/records: run the checks below; keep records in the task directory.

## Rules

- Prepare tasks with understand and plan before `afk run <task-id>`.
- The pinned tatr v2 has no `check` command. Use task-specific proofs.
- Keep tmux extended keys, Nixvim agent integrations, Node.js, tatr, and today
  here.
- Change agent tooling in `~/personal/agents.nix` with its checks.
- Change tatr or today behavior and exported skills together in the owner.
- The local today path input is development wiring. Use its tagged GitHub
  input after release.

## Checks

```bash
nix flake check
nix build .#homeConfigurations.alex.activationPackage --no-link
```

Agent tooling checks run in `agents.nix`. Today and tatr own their checks.
