# AGENTS.md

Global `~/AGENTS.md` applies.

## Project

- NixOS and Home Manager configuration with a root flake.
- Nix is the primary language. Shell, Python, and TypeScript support specific
  modules and tools.
- Host configuration lives in `hosts/`. User configuration lives in `home/`.
- Shared Home Manager modules live in `home/modules/`.

## Agent workflow

- Work directly on `master` unless the user requests an isolated worktree.
- Use tatr for tracked work. Create a task only when the user requests one.
- Use one task for one user request and its follow-up work. Create dependent
  tasks only when the user requests decomposition.
- Store tatr records under `tasks/<id>/`. The pinned tatr v2 has no `check`
  command; use task-specific proof.
- Use sprout only when the user requests an isolated worktree.
- Treat `README.md` and module comments as authoritative domain documentation.
- Use local sources before network research.

## Conventions

- Format Nix code with Alejandra.
- Keep host-specific configuration in `hosts/<name>/` and reusable user
  configuration in `home/modules/`.
- This repository owns global agent instructions, the Pair skill, sprout, and
  the tatr and today integrations.
- Keep tmux extended keys, Nixvim agent integrations, Node.js, sprout, tatr,
  and today in this repository.
- Change sprout with `home/modules/scripts/sprout-test.sh`. Change tatr or today
  behavior and exported integrations together in the owning project.

## Verification

Run the relevant repository checks:

```bash
nix flake check
nix build .#homeConfigurations.alex.activationPackage --no-link
```

Run `home/modules/scripts/sprout-test.sh` for sprout changes. Today and tatr own
their checks.
