# Add tatr-native wayfinding, web research, and retained prototypes

- STATUS: OPEN
- PRIORITY: 70
- TAGS: feature, skills, flow, spike
- KIND: STORY
- FLOW STEP: PLANNING
- PLAN STATUS: DRAFT
- PARENT: 20260730-153122

## Story

As the flow-suite maintainer, I want large or uncertain work to use a
tatr-backed Epic index, cited research, and retained executable prototypes, so
each Story fits one context and decisions are based on evidence.

## Steps

- [ ] Add a wayfinding branch that creates or resumes a tatr Epic index with
      Destination, Decisions, Frontier, Fog, and Out of Scope, then loads only
      the selected Story or discovery task.
- [ ] Add research as a spike/wayfinder mode: browse when external or current
      facts are needed, prefer primary sources, save cited findings in the
      owning task folder, and index only a one-line answer in the Epic.
- [ ] Refactor spike into a concise router for research, logic prototype, UI
      prototype, or mixed evidence, with one direct conditional reference per
      mode.
- [ ] Resolve prototype storage from the AGENTS.md cache, an established
      `examples/`/`scripts/`/`demos/` convention, or
      `tasks/<id>/prototype/`; ask once only when placement has meaningful
      consequences, then cache the answer.
- [ ] Treat repo-native examples/scripts as supported artifacts with a run
      command and build/smoke proof; treat task-local prototypes as retained
      evidence with their command, observations, verdict, and limitations.
- [ ] Route accepted research/prototype decisions into DECISION.md and normal
      planned Stories; do not present exploratory code as production code.
- [ ] Add end-to-end fixtures for Epic resume/frontier behavior, primary-source
      web research, Rust-style examples, task-local HTML prototypes, and
      negative/dropped spikes.
- [ ] Update the skills README and lifecycle cross-references.

## Definition of Done

- A wayfinding run loads the Epic index and one selected child, not every
  Story body (test: `wayfinder_context_index`).
- Web research records primary-source citations and a bounded Epic answer
  (test: `wayfinder_web_research`).
- Rust convention selects `examples/`, an unconfigured HTML fixture selects
  the task folder or asks once, and the confirmed answer is cached
  (test: `prototype_location_resolution`).
- UI and logic prototypes remain runnable from their recorded command after
  the spike closes (test: `retained_prototype_smoke`).
- Accepted decisions seed planned work while DROPPED spikes seed none
  (test: `spike_decision_routing`).
- Repository conformance and flake evaluation pass
  (cmd: `tatr check --ledger LESSONS.md && nix flake check --no-build`).

## Notes

- Parent Epic: 20260730-153122.
- Spike: tasks/20260730-142052/SPIKE.md
- Refinement: tasks/20260730-142540/NOTES.md
- Depends on tatr: 20260730-153325, 20260730-154657, 20260730-154740.
- Depends on nix.dotfiles: 20260730-142533.
