# AGENTS.md

Repo-level guidelines. The global ~/AGENTS.md still applies; this file adds
what is specific to this repository.

## What this repo is

My NixOS and home-manager configuration (flake at the root, hosts under
`hosts/`, home modules under `home/modules/`). It is also the SOURCE of most
agent tooling: the flow-family skills live in `home/modules/agents/skills/`
and the sprout/daily/today CLIs live in `home/modules/scripts/`. Tool-owned
skills can come from their own flakes; the tatr skill is imported from
`inputs.tatr.skills.tatr` when the locked input exposes it. The home-manager
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
  `bash home/modules/scripts/sprout-test.sh`, `tatr check --ledger LESSONS.md`.
- Lessons ledger: `LESSONS.md` at the repo root.

Detail: the Check suite section below.

## Development flow

- `/flow` drives development here: plan/work/review/compound as tatr tasks
  under `tasks/`, each task implemented in a sprout worktree, round-1 reviews
  by an out-of-context reviewer, DoD items with test:/cmd:/manual: proofs.
- `LESSONS.md` at the repo root is the lessons ledger. Read it before
  starting any task; /compound and /lessons maintain it. Records live in
  the task folders (`tasks/<id>/`) and the ledger.
- The conformance gate is `tatr check` plus
  `tatr check --ledger LESSONS.md`; both must exit 0.

## Check suite

- `bash home/modules/scripts/sprout-test.sh` - the sprout CLI's test suite.
- `bash home/modules/agents/skills/check.sh` - the skill-suite conformance
  gate: context budgets, the conditional-reference graph, the invocation
  policy, duplicated rules, and the fixtures under `skills/fixtures/`.
  `--self-test` sabotages each rule in a scratch copy and asserts the gate
  reports that rule, so the gate is never silently vacuous; `--rules` prints
  the inventory it checks coverage against; `--fixture <case>` runs the one
  fixture whose `name:` matches and prints `fixture <case>: ok`, which is how
  a task's Definition of Done names a single criterion as a `cmd:` proof.
  `nix flake check` runs the bare and `--self-test` forms, so this is the fast
  hand-run, not the only run.
- `nix flake check` - flake evaluation AND the `checks` outputs under
  `flake/`, which assert wiring spanning two evaluations (the NixOS config and
  the standalone home config) that evaluating either one alone cannot catch.
  `flake/checks-skills.nix` carries BOTH halves of the skills gate:
  `skills-conformance` runs `check.sh --self-test` and then `check.sh`, and
  `skills-deployment-tree` proves every skill on disk actually reaches Claude
  Code, the AGENTS.md ecosystem and codex. Use the bare form before landing:
  `--no-build` evaluates the checks but does not RUN them, so it proves
  nothing about their assertions.

## Skills are a doc surface

Editing anything the skills describe (sprout behavior, tatr conventions, the
flow itself) invalidates the skill texts in `home/modules/agents/skills/`;
per the docs-sync rule, update those surfaces in the same task, and keep the
skills generic - they run in every repo, not just this one.

They are also budgeted. `flow/SKILL.md` is a dispatcher under 500 words; each
phase body is under 800; branch-specific material goes in a conditional
reference under 1000, pointed at from a `## Load on demand` section and read
only when its condition holds. A rule a tool or template can enforce belongs
there, and the prose it replaces is deleted in the same change. See
`home/modules/agents/skills/README.md`.
