# Add explicit flow dispatch table

- STATUS: OPEN
- PRIORITY: 75
- TAGS: skills, flow, docs
- KIND: TASK
- FLOW STEP: PLANNED
- PLAN STATUS: APPROVED

## Story

As a flow user, I want an explicit state/condition dispatch table, so the
current task state names the next skill and legal transition without relying
on prose inference.

## Steps

- [ ] Replace `flow/SKILL.md`'s numbered `## Route` with one compact table:
      state/condition, invoked skill, and transition/result.
- [ ] Cover all eight tatr lifecycle states, the REVIEWING fix loop, post-DONE
      landing/finish work, and every phase skill dispatched by flow.
- [ ] Route unknown WHAT to `spike` while staying in UNDERSTANDING; state that
      spike is a conditional handoff, not a tatr lifecycle state.
- [ ] Re-read `tatr/lifecycle.md` and each phase body's transition contract;
      remove conflicting or duplicated route prose.
- [ ] Run the skill gate, task/ledger checks, sprout tests, and flake checks.

## Definition of Done

- Flow exposes a state/condition -> skill -> transition/result table and an
  explicit unknown-WHAT -> `spike` route (cmd: `rg -q '^\| State / condition \| Skill \| Transition / result \|$' home/modules/agents/skills/flow/SKILL.md && rg -q '^\| UNDERSTANDING \+ WHAT unknown .*\| `spike` \|' home/modules/agents/skills/flow/SKILL.md`).
- The table covers every tatr state and preserves the guarded review fix loop
  (manual: fresh reviewer compares the table with `tatr/lifecycle.md` and all
  dispatched phase contracts).
- Flow remains at most 300 body words and the skill suite stays conformant
  (cmd: `bash home/modules/agents/skills/check.sh`).
- Repository checks pass (cmd: `bash home/modules/scripts/sprout-test.sh && tatr check --ledger LESSONS.md && nix flake check`).

## Notes

- `tatr` owns lifecycle legality; the table documents routing, not a second
  transition engine.
- Skill descriptions support implicit model selection, but semantic matching
  is non-deterministic. Explicit flow routing makes phase choice inspectable.
- Expected shape: one table replacing prose, not an added graph or reference.
