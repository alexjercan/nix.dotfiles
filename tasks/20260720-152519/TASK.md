# Work skill: docs-sync rule - doc surfaces update in the same task

- STATUS: CLOSED
- PRIORITY: 65
- TAGS: feature, skills

## Story

As the work phase, I want the docs-sync rule global: a change is not done
until every doc surface it invalidates is updated in the same task.
Evidence: bevy-common-systems' stale AGENTS.md (old versions, incomplete
module map) caused a reviewer-confirmed invented-API finding; nova-protocol
promoted keep-docs-in-sync-with-code (x5) locally only.

## Steps

- [x] work SKILL.md verify step: add the doc-surface sweep - grep the doc
      surfaces (README, docs/, AGENTS.md module maps and version claims,
      skill files when the repo ships skills) for every command, flag, type
      or behavior the diff renames or invalidates; fix in the same task.
- [x] work SKILL.md step 4's documentation paragraph: state the rule
      positively - docs are part of the change, not a follow-up.
- [x] review SKILL.md Docs bullet: the reviewer spot-checks the sweep ran
      (pick one renamed symbol/flag and grep the doc surfaces for it).

## Definition of Done

- work SKILL.md contains the rule (cmd: grep -n "doc surface" home/modules/agents/skills/work/SKILL.md)
  and the sweep (cmd: grep -n "DOC-SURFACE SWEEP" home/modules/agents/skills/work/SKILL.md)
  (proof split per review R1.1: the original single grep would still pass
  with the sweep bullet deleted)
- review SKILL.md Docs bullet references it (cmd: grep -n "sweep" home/modules/agents/skills/review/SKILL.md)

## Close-out (2026-07-20)

What changed: work SKILL.md - the documentation paragraph in step 4 now
states the rule positively (docs are part of the change, not a follow-up;
"NEW written documentation" distinguishes creating notes from the sweep),
and the verify step's pitfall list gains the doc-surface sweep with the
concrete evidence (bevy's stale AGENTS.md causing invented API names,
nova's keep-docs-in-sync-with-code at x5). review SKILL.md's Docs bullet
tells the reviewer to spot-check the sweep with one grep. This globalizes
nova-protocol's locally-enforced rule, closing the last-picked of the seven
approved improvements' skill changes.

Difficulties: none; two-file text change. The sweep phrasing reuses the
grep-the-surfaces pattern this flow itself has been executing (sprout land
task updated flow/sprout/docs surfaces in the same task).
