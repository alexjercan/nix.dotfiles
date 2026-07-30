# Decision: Prove the skill suite structurally, not by running an agent

- DATE: 20260731-001344
- STATUS: ACCEPTED
- TASK: 20260730-142533
- TAGS: decision, skills, flow, testing

## Context

This task's Definition of Done names four tests - `skill_progressive_disclosure`,
`skill_invocation_policy`, `skill_output_contracts` and
`skills_deployment_tree` - whose stated criteria describe agent RUNTIME
behavior: which files an agent loads on a branch, which skill it triggers, how
long its chat report is.

Nothing in this repository can observe any of that. A file is "loaded" only
because a model chose to read it; a skill is "selected" only because a model
matched a description. Both are properties of a run, not of the tree. Two
candidate artifacts satisfy the wording, and they are mutually exclusive as the
DoD's `cmd:` proof: one of them cannot execute inside `nix flake check` at all,
because it needs credentials, a network and a non-deterministic model. That
incompatibility is the decision, so it went to the user rather than being
resolved by inferring a shape.

## Decision

Build the deterministic structural gate, and treat live-agent behavior as a
manual acceptance item on the parent Epic.

- `home/modules/agents/skills/check.sh` proves the skill TEXTS conform:
  context budgets, the conditional-reference graph (resolvable, reachable, one
  level deep), typographic characters, the invocation policy, duplicated
  paragraphs, and the declared `## Output` contracts.
- `skills/fixtures/` holds the named cases. A disclosure fixture states a
  branch's words and asserts that each file it should load is guarded by a
  pointer whose stated CONDITION names that branch, and that each file it must
  not load is guarded by a condition naming none of them. That is a real proof
  of unreachability by construction, and it is what the `skill_*` DoD items
  mean here.
- `flake/checks-skills.nix` carries both halves as `nix flake check`
  derivations: `skills-conformance` runs `check.sh --self-test` and then
  `check.sh`, and `skills-deployment-tree` (the plan wrote it
  `skills_deployment_tree`; renamed to match the hyphenated convention the
  sibling check already uses) reads the deployed file set back out of the
  evaluated home config and asserts every skill on disk reaches Claude Code,
  the AGENTS.md ecosystem and codex - recursively, from its own source, with
  its references and its `agents/openai.yaml`.
- `check.sh --self-test` sabotages each rule in a scratch copy and asserts the
  gate reports THAT rule. A gate nothing can trip proves nothing.

The user confirmed they will exercise the live behavior by hand.

## Alternatives considered

- **A live-agent evaluation harness.** Run `claude -p` and `codex exec` per
  fixture and assert on the transcript: files read, skill selected, reply word
  count. Highest fidelity, and the only thing that literally proves the DoD's
  wording. Rejected as the gate: non-deterministic, credential-bound, slow, and
  unable to run inside `nix flake check`, so it would have made the DoD's own
  `cmd:` proof unrunnable. Its value is real but belongs to a human session,
  which is where it now sits.
- **Both, with `--live` as an opt-in mode.** Rejected for this task: the live
  runner is a separate deliverable with its own failure modes (auth, rate
  limits, transcript formats that change under the tool), and shipping a
  half-exercised second mode inside a refactor hides it behind a flag nobody
  runs. It is a legitimate follow-up if the manual pass proves tedious.
- **Skip the tests and rely on review.** Rejected. The budgets and the
  disclosure structure are exactly the properties that rot silently as skills
  are edited, which is the reason this task exists.

## Consequences

Easier: the gate is fast, deterministic, and runs inside `nix flake check`, so
the budgets cannot rot between hand runs. It
fails loudly on the drift that actually happens - a skill body growing past its
budget, a reference nothing points at, a rule copied between two skills, a new
skill folder nobody deployed. `--self-test` keeps it honest.

Harder: the gate proves SHAPE, not obedience. A perfectly shaped suite can
still be ignored by a model that reads every file anyway, and no finding here
will ever say so. That gap is now explicit - in this record, in
`skills/README.md`, in `fixtures/run.sh`, and as the Epic's manual acceptance
item - rather than papered over by a green check whose name promises more than
it delivers.

Also harder: the disclosure fixtures couple to the WORDS of a pointer's
condition. Rewording a `## Load on demand` line can turn a fixture red with no
behavioral change at all. That is deliberate - the condition text is the thing
being asserted - but it makes fixture upkeep part of editing a skill.
