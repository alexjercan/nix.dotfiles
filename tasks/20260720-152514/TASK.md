# Ledger lifecycle: RETIRED marker, promotion order, shrink-on-absorb

- STATUS: OPEN
- PRIORITY: 70
- TAGS: feature,skills

## Story

As the compounding loop, I want ledger lifecycle rules written into the
lessons and compound skills, so the ledger stays trustworthy as it ages:
dead lessons are retired instead of lingering, and promotions prefer making
mistakes impossible over adding prose. Evidence: scufris invented a RETIRED
marker ad hoc; the tatr same-second guard killed a x7 lesson that prompt
warnings never fixed.

## Steps

- [ ] lessons SKILL.md ledger format + guidelines: RETIRED marker - slug
      kept, dated, one-line reason, never bumped again; pruned at the first
      release after retirement.
- [ ] lessons SKILL.md: promotion-order rule - tool > template/format >
      skill text; promotion starts by asking whether a CLI guard or a
      template change can make the mistake impossible, and only falls back
      to skill prose.
- [ ] Shrink-on-absorb rule: when a tool or template absorbs a lesson, the
      skill prose it replaced is DELETED in the same change and the ledger
      entry gains `(absorbed by <tool>, <date>)`.
- [ ] compound SKILL.md step 6: sharpen the existing tool-bug bullet into
      the ordered rule and point at the lessons skill for the lifecycle.

## Definition of Done

- lessons SKILL.md contains RETIRED, the promotion order and
  shrink-on-absorb (cmd: grep -n "RETIRED\|absorb" home/modules/agents/skills/lessons/SKILL.md)
- compound SKILL.md step 6 states the order (cmd: grep -n "tool > template" home/modules/agents/skills/compound/SKILL.md)
