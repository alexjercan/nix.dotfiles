# AGENTS.md

Repo-level guidelines. The global ~/AGENTS.md still applies; this file adds
what is specific to this repository.

## What this repo is

My NixOS and home-manager configuration (flake at the root, hosts under
`hosts/`, home modules under `home/modules/`). It is also the SOURCE of most
agent tooling: the agent skills live in `home/modules/agents/skills/`
and the sprout/afk/today CLIs live in `home/modules/scripts/`. Tool-owned
skills can come from their own flakes; `tatr` and `knowledge` are imported
from their locked inputs when exposed. The home-manager
agents module deploys each managed skill to `~/.claude/skills` (Claude Code),
`~/.agents/skills` (the AGENTS.md ecosystem) and `~/.codex/skills` (codex, as
real file copies - its scanner ignores a symlinked SKILL.md), and deploys the
global `home/modules/agents/AGENTS.md` to `~/AGENTS.md`.

## Agent workflow

- Tracker: tatr, records under `tasks/<id>/`. Tasks have no kind; a
  multi-task goal is a `-d` dependency graph. One requested thing is one task.
- Examples and prototypes: none in-tree; an understand phase's exploratory
  prototype is retained under `tasks/<id>/prototype/`. Verification lives in
  `flake/checks*.nix` and the shell test scripts under `home/modules/scripts/`.
- Domain docs: none. `README.md` plus the module comments are the reference.
- Research: local sources first; no network is required by any check.
- Canonical checks: `nix flake check`,
  `bash home/modules/agents/skills/check.sh`,
  `bash home/modules/scripts/sprout-test.sh`,
  `bash home/modules/scripts/afk-test.sh`, `tatr check`.
- Knowledge: central repo `/home/alex/personal/agent-knowledge`; project=nix.dotfiles; tags=agents,nix,afk,skills. Advisory only; failed writes stay in RETRO.

Detail: the Check suite section below.

## Development workflow

- Prepare tasks with `understand` and `plan`. `afk run <task-id>` accepts only
  a TASK.md with non-empty Steps and Definition of Done.
- `afk` drives work, review, compound, sync, verification, and landing. Each
  task uses one sprout worktree. BLOCKER/MAJOR findings return to work.
- `compound` writes RETRO. `afk` then applies the knowledge policy, closes the
  task, syncs, verifies, and lands.
- `human:` proofs stay pending and do not block review approval.
- Records live under `tasks/<id>/`. The conformance gate is `tatr check`.

## Check suite

- `bash home/modules/scripts/sprout-test.sh` - the sprout CLI's test suite.
- `bash home/modules/scripts/afk-test.sh` - the afk runner's test suite. It
  drives the real script against throwaway repos with a fake `claude` first on
  PATH, so it proves the control logic (session rotation, the mechanical
  gates, state cross-checks, stop policy) without spending model quota. Like
  `sprout-test.sh` it is a hand-run check, not part of `nix flake check`.
- `bash home/modules/agents/skills/check.sh` - structural skill checks:
  frontmatter, metadata, ASCII-adjacent writing, and 250-word body budgets.
  It does not prove instruction quality.
- `nix flake check` - flake evaluation AND the `checks` outputs under
  `flake/`, which assert wiring spanning two evaluations (the NixOS config and
  the standalone home config) that evaluating either one alone cannot catch.
  `flake/checks-skills.nix` carries BOTH halves of the skills gate:
  `skills-conformance` runs `check.sh`, and
  `skills-deployment-tree` proves every local skill on disk and external
  tool-owned skill actually reaches Claude Code, the AGENTS.md ecosystem and
  codex. Use the bare form before landing:
  `--no-build` evaluates the checks but does not RUN them, so it proves
  nothing about their assertions.

## Skills are a doc surface

Editing anything the skills describe (sprout behavior, tatr conventions, or
the afk workflow) invalidates the skill texts in `home/modules/agents/skills/`;
per the docs-sync rule, update those surfaces in the same task, and keep the
skills generic - they run in every repo, not just this one.

`home/modules/scripts/afk.sh` owns autonomous orchestration and its private
`CONTINUE`, `FLOW_DONE`, and `BLOCKED` protocol. It requires an existing
planned task. Change `afk.sh` and `afk-test.sh` together when this contract
changes.

Every managed SKILL.md body is at most 250 words. Put enforceable rules in
tools or templates. See `home/modules/agents/skills/README.md`.
