# Refactor flow skills for bounded context and concise output

- STATUS: OPEN
- PRIORITY: 80
- TAGS: feature,skills,flow,docs,spike

## Flow State

- FLOW STEP: PLANNED
- PLAN STATUS: APPROVED

## Story

As the flow-suite maintainer, I want each skill to load only the instructions
needed for its current branch and phase, so that repository context and
reasoning receive most of the context window.

## Steps

- [ ] Define the single owner and target word budget for every flow-family
      rule, description, core body, conditional reference, phase handoff, and
      user-facing report.
- [ ] Refactor `flow` into a compact state-machine dispatcher and refactor each
      phase skill so its core path stays in SKILL.md while branch-specific
      material is loaded through direct, conditional references.
- [ ] Remove repeated lifecycle/tool details, historical anecdotes, embedded
      record templates, and redundant Relationship sections once their
      behavior is owned by tatr, sprout, a scaffold, or the orchestrator.
- [ ] Add explicit Codex and Claude invocation metadata; keep only skills that
      need automatic or cross-skill reach implicitly invocable, with concise
      branch-complete descriptions.
- [ ] Add the repository-workflow cache convention: AGENTS.md stores short
      answers for tracker, Epic/Story layout, example/prototype location,
      research policy, domain docs, and canonical checks, with detail behind
      one pointer.
- [ ] Add phase output contracts and bounded subagent handoffs; durable task
      artifacts hold detail while chat reports only result, proof, next step,
      and required status marker.
- [ ] Add `home/modules/agents/skills/check.sh` plus integration fixtures for
      budgets, ASCII, frontmatter, broken/indirect references, duplicated
      paragraphs, invocation policy, conditional loading, and output shape.
- [ ] Update the skills README and deployment checks so references,
      templates/assets, and `agents/openai.yaml` files reach both agent tools.

## Definition of Done

- Flow-family descriptions total at most 200 words, `flow/SKILL.md` is at most
  500 body words, each phase core is at most 800, and each conditional
  reference is at most 1,000 (cmd:
  `bash home/modules/agents/skills/check.sh`).
- Fixture prompts prove branch-only references are not loaded on unrelated
  paths (test: `skill_progressive_disclosure`).
- Codex and Claude fixtures select the same intended implicit/explicit skills
  (test: `skill_invocation_policy`).
- Phase reports satisfy the agreed output limits without omitting required
  findings, proofs, gates, or status markers (test: `skill_output_contracts`).
- The home-manager activation result contains every required skill body,
  reference, asset/template, and OpenAI metadata file
  (test: `skills_deployment_tree`).
- Repository conformance and flake evaluation pass
  (cmd: `tatr check --ledger LESSONS.md && nix flake check --no-build`).

## Notes

- Parent Epic: 20260730-153122.
- Spike: tasks/20260730-142052/SPIKE.md
- Refinement: tasks/20260730-142533/NOTES.md
- Depends on tatr: 20260730-153325, 20260730-154745.
- Preserve the current tatr task, sprout isolation, proof-bearing DoD, review,
  landing, and lessons lifecycle.
