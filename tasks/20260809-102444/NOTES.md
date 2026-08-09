# Notes: Extract agent tooling into an agents.nix flake

## Problem Statement

Agent-related configuration has made `nix.dotfiles` bloated and gives this
personal system repository ownership of reusable agent tooling.

## Context

Target: a separate flake at `~/personal/agents.nix`, consumed by
`nix.dotfiles`, with no production changes during this understand phase.

Decisions:

- Move `sprout`, its package/tests, and its skill with the agent workspace.
- Keep `tatr` owned and installed by `nix.dotfiles`. Let `agents.nix` follow
  that input for afk's runtime dependency and include its exported skill among
  the built-in workspace skills. Only today is injected through `extraSkills`.
- Start with a personal, opinionated flake. Add options only for known needs.
- Use a local path input during development. Switch to GitHub for the first
  release.
- Put all skill, package, and module checks in `agents.nix`. Do not retain an
  agent integration check in `nix.dotfiles`.
- Move installation and configuration for Pi, OpenCode, Codex, Claude Code,
  and agent-browser. Preserve behavior, but refactor weak internals.
- Add `skills.today` to the `today` flake and supply it through `extraSkills`.
- Keep Pi's tmux extended-key settings, Nixvim integrations, and `nodejs` in
  `nix.dotfiles`.
- Start `agents.nix` with fresh history. The old source history remains in
  `nix.dotfiles`.

Current ownership and discovered edges:

- `home/modules/agents/` installs the harnesses and knowledge, imports Pi,
  deploys global instructions, and deploys skills to Claude, the shared
  `.agents` root, and Codex.
- `home/modules/scripts/` owns `afk` and `sprout`; its remaining `today` module
  is unrelated and can stay in `nix.dotfiles`.
- Root inputs own `pi`, `tatr`, and `agent-knowledge`. The Home Manager package
  set adds tatr and knowledge overlays.
- `afk` directly runs `tatr edit` once when an OPEN task starts, changing it to
  IN_PROGRESS through the tracker's validated interface. Its Claude child
  sessions also inherit afk's runtime PATH, and the protocol expects the task
  to become CLOSED before landing. The runner reads and validates other task
  state itself.
- `flake/checks-skills.nix` mixes source policy, deployment checks, and
  `nix.dotfiles`-specific knowledge assertions. The new flake must split these
  concerns rather than copy the check unchanged.
- Pi discovers `~/.agents/skills` directly. The shared skill deployment already
  gives Pi the same skills without Pi-specific copies or `programs.pi` skill
  arguments.
- Pi's documented tmux setup is the recently added `extended-keys` and
  `extended-keys-format csi-u` configuration. It remains part of the personal
  tmux configuration in `nix.dotfiles`.
- `home/modules/neovim/plugins/copilot.nix` and `_99.nix` are agent-adjacent
  editor integrations. `_99.nix` invokes OpenCode or Claude providers.
- The Pi commit also added `nodejs` to general development packages, but no
  configuration names it as a Pi dependency. The Pi Nix package is already
  self-contained.
- The `today` skill is agent-facing, but the `today` v0.1.0 flake does not
  export it. This is the same ownership shape as tatr, without an upstream
  skill output yet.
- The current Codex activation copies only current skills. Removing a managed
  skill leaves its old real-file copy behind. A managed-name manifest can make
  removal and module disable clean while preserving Codex `.system` and other
  unmanaged skills.
- Input-owned and extra skills cannot be held to all local policy. For example,
  the built-in tatr skill has a valid `SKILL.md` but no `agents/openai.yaml`.
  Strict body, metadata, and style checks apply to locally owned skills;
  input-owned skills need a valid deployable source and collision-safe name.
- The earlier overlapping Pi changes are now committed. The worktree is clean
  except for this task directory.
- The pinned tatr v2 CLI has no `check` subcommand, although the repository
  instructions still name `tatr check`. Documentation refresh must remove that
  stale command; task readability can be proved with `tatr ls`.

## Questions

None.

## Ideas

Proposed consumer interface:

```nix
inputs.agents = {
  url = "path:/home/alex/personal/agents.nix";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.home-manager.follows = "home-manager";
  inputs.tatr.follows = "tatr";
};

imports = [inputs.agents.homeModules.default];

programs.agents = {
  enable = true;
  extraSkills.today = inputs.today.skills.today;
};
```

- `extraSkills` is an attribute set from deployment name to source path. Reject
  collisions with built-in names instead of silently overriding them.
- Candidate outputs: `homeModules.default`, `packages.afk`, `packages.sprout`,
  built-in `skills`, and `checks`.
- The Home Manager module captures its own Pi and knowledge inputs. It does not
  depend on the consumer's generic `inputs` special argument.
- Keep Home Manager symlink deployment for Claude and `~/.agents`; it is
  declarative and lets unmanaged skills coexist. Keep real copies for Codex,
  but add a managed-name manifest for stale cleanup and disable behavior.
- Evaluate an isolated Home Manager fixture inside `agents.nix` to check module
  deployment. Run skill conformance plus the existing `afk` and `sprout`
  integration suites there. `nix.dotfiles` only imports and configures the
  module.
- Keep the deployable global instructions separate from the new repository's
  root `AGENTS.md`; repository-specific instructions must not become global
  user instructions.
- Update the `today` flake to export its skill, then configure it under
  `extraSkills` in `nix.dotfiles`. Deploy tatr from the followed input as a
  built-in workspace skill.
- Leave the personal tmux and Nixvim integrations and `nodejs` in
  `nix.dotfiles`.
- Update `nix.dotfiles` documentation to identify the external owner, while
  retaining repository-specific workflow guidance that still applies here.

Prototype: `prototype/module-interface.nix` and `prototype/eval.nix` model the
`enable`, `extraSkills`, and internal merged-skill interface. Evaluation proves
that a named tatr source merges with a built-in skill and that a duplicate name
fails. A second evaluation with the real `inputs.tatr.skills.tatr` store path
also succeeds.

```bash
nix-instantiate --eval --strict --json \
  tasks/20260809-102444/prototype/eval.nix
```
