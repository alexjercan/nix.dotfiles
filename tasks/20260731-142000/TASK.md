# Review prose changes against neighboring contracts

- STATUS: OPEN
- PRIORITY: 60
- TAGS: skills,review,lessons,docs
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

As a flow reviewer, I want prose changes checked against neighboring contracts
and cross-references, so concise rewrites do not silently change behavior.

## Steps

- [ ] Add a concise rule to
      `home/modules/agents/skills/review/SKILL.md`: for prose/contract edits,
      re-read neighboring rules and sweep changed concepts plus cross-references.
- [ ] Keep the review body within 400 words and preserve all existing review
      behavior.
- [ ] Run the skill gate, task/ledger checks, and full flake checks.
- [ ] After landing, apply the `fix-touches-its-neighbours` PROMOTED transition
      in `LESSONS.md` and move it back to Process lessons.

## Definition of Done

- Review requires both a neighboring-rule read and concept/cross-reference
  sweep after prose contract changes (cmd: `grep -q 'neighboring rules' home/modules/agents/skills/review/SKILL.md && grep -q 'cross-references' home/modules/agents/skills/review/SKILL.md`).
- The compact skill suite passes with review at most 400 body words
  (cmd: `grep -q 'neighboring rules' home/modules/agents/skills/review/SKILL.md && bash home/modules/agents/skills/check.sh`).
- (manual: fresh reviewer confirms the rule covers the three
  `fix-touches-its-neighbours` occurrences without duplicating generic docs
  guidance).
- Repository checks pass (cmd: `grep -q 'neighboring rules' home/modules/agents/skills/review/SKILL.md && tatr check && tatr check --ledger LESSONS.md && nix flake check`).

## Notes

- Promoted lesson: `fix-touches-its-neighbours` x3.
- Seeded by task 20260731-133122 review/retro.
- Promotion order audit found no reliable semantic checker or template owner;
  review prose is the narrowest owner.
