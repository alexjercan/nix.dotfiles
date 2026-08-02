# AGENTS.md

Repo-level guidelines. The global ~/AGENTS.md still applies; this file adds
what is specific to this repository.

## What this repo is

My NixOS and home-manager configuration (flake at the root, hosts under
`hosts/`, home modules under `home/modules/`). It is also the SOURCE of most
agent tooling: the flow-family skills live in `home/modules/agents/skills/`
and the sprout/afk/today CLIs live in `home/modules/scripts/`. Tool-owned
skills can come from their own flakes; `tatr` and `knowledge` are imported
from their locked inputs when exposed. The home-manager
agents module deploys each managed skill to `~/.claude/skills` (Claude Code),
`~/.agents/skills` (the AGENTS.md ecosystem) and `~/.codex/skills` (codex, as
real file copies - its scanner ignores a symlinked SKILL.md), and deploys the
global `home/modules/agents/AGENTS.md` to `~/AGENTS.md`.

## Agent workflow

- Tracker: tatr, records under `tasks/<id>/`. Epics are `KIND: EPIC` with
  `KIND: STORY` children; one requested thing is one task.
- Examples and prototypes: none in-tree; a spike's exploratory prototype is
  retained under `tasks/<id>/prototype/`. Verification lives in
  `flake/checks*.nix` and the shell test scripts under `home/modules/scripts/`.
- Domain docs: none. `README.md` plus the module comments are the reference.
- Research: local sources first; no network is required by any check.
- Canonical checks: `nix flake check`,
  `bash home/modules/agents/skills/check.sh`,
  `bash home/modules/scripts/sprout-test.sh`,
  `bash home/modules/scripts/afk-test.sh`, `tatr check`.
- Knowledge: central repo `/home/alex/personal/agent-knowledge`; project=nix.dotfiles; tags=agents,nix,flow,skills. Advisory only; failed writes stay in RETRO.

Detail: the Check suite section below.

## Development flow

- `/flow` drives development here: plan/work/review/compound as tatr tasks
  under `tasks/`, each task implemented in a sprout worktree, round-1 reviews
  by an out-of-context reviewer, DoD items with test:/cmd:/manual: proofs.
- Records live in the task folders (`tasks/<id>/`). `/compound` writes RETRO
  and routes reusable observations through the `knowledge` skill.
- The conformance gate is `tatr check`; it must exit 0.

## Check suite

- `bash home/modules/scripts/sprout-test.sh` - the sprout CLI's test suite.
- `bash home/modules/scripts/afk-test.sh` - the afk runner's test suite. It
  drives the real script against throwaway repos with a fake `claude` first on
  PATH, so it proves the control logic (session rotation, gate resumes, state
  cross-checks, stop policy) without spending model quota. Like
  `sprout-test.sh` it is a hand-run check, not part of `nix flake check`.
- `bash home/modules/agents/skills/check.sh` - the skill-suite conformance
  gate: context budgets, the conditional-reference graph, the invocation
  policy, duplicated rules, a present `## Output` contract, and
  `direct-state-edit` (no flow-family skill may tell an agent to write a
  lifecycle marker by hand - `tatr flow` owns those). `--rules` prints the
  rule inventory. Runs in about
  two seconds; every rule is structural, so it proves the files have the right
  SHAPE and never that a reference still states the rule it carries. That is a
  review question.
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

Editing anything the skills describe (sprout behavior, tatr conventions, the
flow itself) invalidates the skill texts in `home/modules/agents/skills/`;
per the docs-sync rule, update those surfaces in the same task, and keep the
skills generic - they run in every repo, not just this one.

The flow skill also has a MACHINE consumer now: `home/modules/scripts/afk.sh`.
Two vocabularies meet there, and only one is shared. `afk.sh` sends the three
approve labels in `flow/gates.md` verbatim, and routes on `SPIKED`,
`PLAN_READY`, `WORK_DONE` and `LAND_READY` from the skills' `## Output`
contracts. `ROTATE`, `DONE` and `BLOCKED` are afk's own, defined only in its
PROTOCOL heredoc; no skill declares them. Changing a label or a shared status
means changing `afk.sh` and `afk-test.sh` in the same task.

They are also budgeted. `flow/SKILL.md` is at most 300 words; each other skill
body is at most 400; each conditional reference is at most 600, pointed at
from a `## Load on demand` section and read
only when its condition holds. A rule a tool or template can enforce belongs
there, and the prose it replaces is deleted in the same change. See
`home/modules/agents/skills/README.md`.
