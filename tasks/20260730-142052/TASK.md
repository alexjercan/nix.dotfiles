# Spike: redesign the flow skills for concise progressive disclosure

- STATUS: CLOSED
- PRIORITY: 80
- TAGS: spike,skills,flow,docs
- KIND: SPIKE
- FLOW STEP: DONE
- PLAN STATUS: APPROVED

## Story

As the maintainer of the local flow skill suite, I want a comparative review
of Matt Pocock's skills and the local skills, so that I can reduce context use,
improve planning and prototyping, and preserve the local tatr/sprout lifecycle.

## Question

Which ideas from `/home/alex/third-party/skills` should improve the local
flow-family skills, while preserving the stronger tatr, sprout, review, and
lessons lifecycle? A good answer must reduce context and user-facing prose,
add conditional parallel planning and executable prototypes, and remain
concrete enough to plan without changing the skills yet. (Stated in full, with
its context and answer, in SPIKE.md.)

## Definition of Done

- Compare the architecture, orchestration, context loading, output discipline,
  planning, prototyping, review, and learning loops of both skill sets.
  (manual: SPIKE.md comparison matrix)
- Measure the current instruction surface and identify the largest sources of
  avoidable context use. (manual: SPIKE.md measurements and findings)
- Recommend a concise target architecture and an ordered migration plan
  without changing the skills. (manual: SPIKE.md recommendation)

## Notes

- Source: /home/alex/third-party/skills
- Local skills: home/modules/agents/skills
- Exploration only. Do not implement skill changes in this task.
