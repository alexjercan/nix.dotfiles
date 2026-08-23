# AGENTS.md

Global `~/AGENTS.md` applies. This file defines project-specific instructions.

## Project

- NixOS and Home Manager configuration with a root flake.
- Host configuration lives in `hosts/`. User configuration lives in `home/`.
- Reusable Home Manager modules live in `home/modules/`.

## Workflow

- Work directly on `master` unless the user requests an isolated worktree.
- Use Tatr for requested tracked work. Keep one task for one request and its
  follow-up work.
- Use Sprout only when the user requests an isolated worktree.
- Keep task records under `tasks/<id>/`.
- Treat `README.md` and module comments as authoritative documentation.
- Use local sources before network research.

## Conventions

- Prefer correct, simple, maintainable changes over compatibility machinery.
- Keep scope focused. Comment why, not what.
- Format Nix with Alejandra.
- Keep host-specific configuration in `hosts/<name>/` and reusable user
  configuration in `home/modules/`.
- This repository owns the global agent baseline and agent tool integrations.
- Change Tatr or Today behavior and exported integrations together in the
  owning project.
- Run the cheapest relevant check. Use `nix flake check` for broad integration
  and build `.#homeConfigurations.alex.activationPackage` for Home Manager
  behavior.
