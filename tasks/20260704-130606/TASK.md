# Cross-reference spike into the plan, flow and tatr skill lifecycle

- STATUS: CLOSED
- PRIORITY: 50
- TAGS: docs,skills,historical

## Goal

Make the lifecycle documentation coherent now that `spike` exists at the front
of it. The sibling skills describe the plan-work-review-compound loop and
where each fits; they should mention that a spike can precede planning and
feed it durable research. Small, surgical doc edits only.

## Steps

- [x] In `plan/SKILL.md`, note in the relevant/relationship section that a
      `/spike` can precede planning: when the problem is still fuzzy, spike it
      first to produce a research doc and seed tasks, then `/plan` expands
      those into steps. Point at the spike doc as input.
- [x] In `flow/SKILL.md`, mention in the relationship/relevant section that a
      spike is the optional pre-step that turns an undefined goal into a
      researched one before a flow drives it, and that a flow can consume a
      `docs/spikes/` artifact as its starting point.
- [x] In `tatr/SKILL.md`, where it lists the plan-work-review-compound cycle,
      add spike as the optional front stage ("`/spike` explores, `/plan`
      scopes, ...") so the canonical lifecycle sentence includes it.
- [x] Keep edits minimal and consistent in tone; do not restructure the files.
      ASCII punctuation per AGENTS.md.

## Implementation log

- plan/SKILL.md: added a paragraph after the intro drawing the what-vs-how
  line - planning assumes the what is decided; if it is not, `/spike` first,
  and plan later expands the spike's coarse tasks into steps.
- flow/SKILL.md: extended the canonical "tatr tracks, `/plan` scopes ..."
  lifecycle sentence to include `/spike` explores, and added that a flow can
  start from a `docs/spikes/` doc + its seeded tasks, which flow's own `/plan`
  phase breaks into steps. Closes review finding R1.2 from task 20260704-130605.
- tatr/SKILL.md: extended the "no Steps yet -> plan first" note so that when
  even planning is premature, `/spike` explores first; states the fullest
  cycle as spike, plan, work, review, compound.
- Verified: ASCII-only across all three files; `nix build` of the activation
  package still succeeds. Edits are additive prose only, no restructuring.

## Notes

- Depends on: 20260704-130605 (spike skill must exist first, so its exact
  name, description and positioning are settled before other skills reference
  it).
- Precedent: commit 841bff5 "docs(skills): cross-reference sprout, flow and
  tatr lifecycle" did the same kind of surgical cross-referencing.
- Files: home/modules/agents/skills/{plan,flow,tatr}/SKILL.md. Grep for the
  existing "plan, work, review, compound" lifecycle phrasing to find the exact
  spots to extend.
