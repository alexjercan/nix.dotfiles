# Ledger lifecycle: RETIRED marker, promotion order, shrink-on-absorb

- STATUS: CLOSED
- PRIORITY: 70
- TAGS: feature, skills

## Story

As the compounding loop, I want ledger lifecycle rules written into the
lessons and compound skills, so the ledger stays trustworthy as it ages:
dead lessons are retired instead of lingering, and promotions prefer making
mistakes impossible over adding prose. Evidence: scufris invented a RETIRED
marker ad hoc; the tatr same-second guard killed a x7 lesson that prompt
warnings never fixed.

## Steps

- [x] lessons SKILL.md ledger format + guidelines: RETIRED marker - slug
      kept, dated, one-line reason, never bumped again; pruned at the first
      release after retirement.
- [x] lessons SKILL.md: promotion-order rule - tool > template/format >
      skill text; promotion starts by asking whether a CLI guard or a
      template change can make the mistake impossible, and only falls back
      to skill prose.
- [x] Shrink-on-absorb rule: when a tool or template absorbs a lesson, the
      skill prose it replaced is DELETED in the same change and the ledger
      entry gains `(absorbed by <tool>, <date>)`.
- [x] compound SKILL.md step 6: sharpen the existing tool-bug bullet into
      the ordered rule and point at the lessons skill for the lifecycle.

## Definition of Done

- lessons SKILL.md contains RETIRED, the promotion order and
  shrink-on-absorb (cmd: grep -n "RETIRED\|absorb" home/modules/agents/skills/lessons/SKILL.md)
- compound SKILL.md step 6 states the order (cmd: grep -n "tool > template" home/modules/agents/skills/compound/SKILL.md)

## Close-out (2026-07-20)

What changed: lessons SKILL.md step 4 gained the promotion order
(tool > template/format > skill text, "prose warns, tools prevent"),
shrink-on-absorb (absorbing tool deletes the prose it replaced in the same
change; ledger annotation becomes "absorbed by <tool>, <date>"), and the
RETIRED marker (kept as history, pruned at the first release pass after
retirement, never silently dropped). The Ledger format block unifies all
three annotations as lifecycle markers sharing the lint exemption from
20260720-152508's bare-counts convention, with example entries for
absorbed and RETIRED forms (rule-and-example-must-agree). A guideline
pins retirement as explicit bookkeeping. compound step 6's two promotion
bullets merged into the ordered rule pointing at the lessons skill for
the lifecycle.

Design note: RETIRED/absorbed reuse the annotation mechanism rather than
new syntax, so the existing tatr check --ledger exemption covers them
without a tool change.

Difficulties: none; the 152508 bare-counts convention gave the lifecycle
markers a ready-made home.
