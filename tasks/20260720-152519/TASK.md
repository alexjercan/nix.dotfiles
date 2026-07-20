# Work skill: docs-sync rule - doc surfaces update in the same task

- STATUS: OPEN
- PRIORITY: 65
- TAGS: feature,skills

## Story

As the work phase, I want the docs-sync rule global: a change is not done
until every doc surface it invalidates is updated in the same task.
Evidence: bevy-common-systems' stale AGENTS.md (old versions, incomplete
module map) caused a reviewer-confirmed invented-API finding; nova-protocol
promoted keep-docs-in-sync-with-code (x5) locally only.

## Steps

- [ ] work SKILL.md verify step: add the doc-surface sweep - grep the doc
      surfaces (README, docs/, AGENTS.md module maps and version claims,
      skill files when the repo ships skills) for every command, flag, type
      or behavior the diff renames or invalidates; fix in the same task.
- [ ] work SKILL.md step 4's documentation paragraph: state the rule
      positively - docs are part of the change, not a follow-up.
- [ ] review SKILL.md Docs bullet: the reviewer spot-checks the sweep ran
      (pick one renamed symbol/flag and grep the doc surfaces for it).

## Definition of Done

- work SKILL.md contains the sweep and the rule (cmd: grep -n "doc surface" home/modules/agents/skills/work/SKILL.md)
- review SKILL.md Docs bullet references it (cmd: grep -n "sweep" home/modules/agents/skills/review/SKILL.md)
