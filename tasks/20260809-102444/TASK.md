# Extract agent tooling into an agents.nix flake

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: agents, nix, refactor

## Problem Statement

Agent-related configuration has made `nix.dotfiles` bloated and gives this
personal system repository ownership of reusable agent tooling.

## Context

Create a separate flake at `~/personal/agents.nix`. Factor agent-related
concerns out of this repository, including the `afk` script, skills, agent
harnesses, Pi configuration, and the `agent-knowledge` input. Make
`nix.dotfiles` consume the new flake while preserving the deployed agent
environment and its verification coverage.

## Steps

- [x] In `/home/alex/personal/today`, move the `today` skill tree to
      `skills/today`, export it as `skills.today`, and document the new flake
      output. Preserve the existing unrelated task-record edits in that
      worktree.
- [x] Create the fresh `/home/alex/personal/agents.nix` Git project. Add its
      flake metadata, README, repository instructions, deployable global
      instructions, and package definitions for `afk` and `sprout`. Move both
      scripts and their integration tests without changing their CLI behavior.
      Declare Pi, agent-knowledge, and tatr as direct dependencies; include the
      tatr skill by default; and expose `homeModules.default`, `packages.afk`,
      `packages.sprout`, and built-in `skills` outputs.
- [x] Implement `programs.agents` in the new Home Manager module, following
      `prototype/module-interface.nix`: an `enable` switch plus collision-safe
      `extraSkills`. Merge the workflow, sprout, knowledge, and tatr skills;
      install Pi, OpenCode, Codex, Claude Code, agent-browser, knowledge, afk,
      and sprout; and deploy the shared global instructions and skills to Claude
      and `~/.agents` only while enabled.
- [x] Replace the inline Codex copying with a manifest-backed, testable helper.
      Materialize real skill files for Codex, remove names managed by the prior
      generation, clean them when `programs.agents.enable = false`, and preserve
      `.system` plus all unmanaged skills.
- [x] Move agent-owned verification into `agents.nix`: strict conformance for
      locally owned skills, afk and sprout integration suites, package builds,
      Codex materialization tests, and an isolated Home Manager evaluation
      covering enabled/disabled states, built-in and extra skill deployment,
      collision rejection, and the knowledge package/skill pair. Do not require
      input-owned or extra skills to carry local-only metadata.
- [x] Rewire `nix.dotfiles` to local `path:` inputs for `agents.nix` and the
      updated `today` checkout. Follow the root nixpkgs, Home Manager, and tatr
      inputs; enable `programs.agents`; and pass only the today output via
      `extraSkills`. Remove the direct Pi and agent-knowledge inputs/overlay,
      the in-tree agent module and checks, and the afk/sprout script modules.
      Keep tatr and today installation, tmux extended keys, Nixvim integrations,
      and Node.js in this repository.
- [x] Refresh all affected lock files and documentation. Make each repository's
      ownership and check commands accurate, retain `nix.dotfiles` workflow
      guidance that still applies to consumers, and re-read all three diffs for
      accidental changes or duplicated sources.

## Definition of Done

- The today flake exports a complete skill tree (cmd: `test -f "$(nix eval
  --raw path:/home/alex/personal/today#skills.today)/SKILL.md"`).
- The new flake exposes the Home Manager module, afk/sprout packages, and
  built-in skills (cmd: `test "$(nix eval --json
  path:/home/alex/personal/agents.nix#homeModules --apply 'x: x ? default')"
  = true && test "$(nix eval --json
  path:/home/alex/personal/agents.nix#packages.x86_64-linux --apply 'x: x ?
  afk && x ? sprout')" = true && test "$(nix eval --json
  path:/home/alex/personal/agents.nix#skills --apply 'x: x ? plan && x ?
  sprout && x ? knowledge && x ? tatr')" = true`).
- Locally owned skill policy, package construction, script behavior, Codex
  cleanup, and isolated module deployment all pass in their owning repository
  (cmd: `nix flake check path:/home/alex/personal/agents.nix`).
- The moved shell integration suites still pass directly (cmd: `bash
  /home/alex/personal/agents.nix/scripts/sprout-test.sh && bash
  /home/alex/personal/agents.nix/scripts/afk-test.sh`).
- Enabling the module deploys built-in tatr and external today from their
  owning flake outputs (cmd: `nix eval --raw
  .#homeConfigurations.alex.config.home.file
  --apply 'files: builtins.toString
  files.".agents/skills/tatr".source' && nix eval --raw
  .#homeConfigurations.alex.config.home.file --apply 'files:
  builtins.toString files.".agents/skills/today".source'`).
- `nix.dotfiles` no longer owns agent sources or dedicated agent checks (cmd:
  `test ! -e home/modules/agents && test ! -e
  home/modules/scripts/afk.sh && test ! -e home/modules/scripts/sprout.sh &&
  test ! -e flake/checks-skills.nix`).
- The consuming configuration still evaluates, passes its own checks, and
  builds the enabled Home Manager activation package (cmd: `nix flake check &&
  nix build .#homeConfigurations.alex.activationPackage --no-link`).
- The task remains readable by the pinned tatr v2 CLI (cmd: `set -o
  pipefail; tatr ls | grep -F 'tasks/20260809-102444/TASK.md'`).
- The new repository has fresh history, and the retained tmux, Nixvim, Node.js,
  tatr, and today configuration remains behaviorally unchanged (human: inspect
  repository histories and the three final diffs).

## Work Notes

- Extracted agent ownership into a fresh, staged `agents.nix` repository. Tatr
  remains rooted in `nix.dotfiles`, follows into the workspace for afk, and now
  supplies a built-in skill. Today owns and exports the only configured extra
  skill.
- Kept Home Manager links for Claude and `~/.agents`. Added a manifest-backed
  Codex materializer because Codex requires real files and the old activation
  left removed skills stale. Its integration test covers replacement, disable
  cleanup, invalid input, README handling, and preservation of unmanaged data.
- The first Nix afk integration build exposed generated `#!/usr/bin/env bash`
  scripts, which fail in a sandbox without `/usr/bin/env`. The test now embeds
  the active Bash store path; direct behavior remains unchanged.
- Verified every `cmd:` proof. Also passed the today flake checks and the direct
  skill and Codex helper suites. The final `human:` diff/history proof remains
  for review.
