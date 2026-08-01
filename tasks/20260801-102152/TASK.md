# Close-out Evidence rule: a bare number sits next to the command that printed it

- STATUS: OPEN
- PRIORITY: 40
- TAGS: chore,process,lessons
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Context

Promotion of ledger lesson `record-numbers-from-a-rerun` (x3: 20260731-172224,
20260731-172233, 20260801-100108), disposition PROMOTE -> template, decided
2026-08-01.

The recurring failure is a number written from memory of a scrolled-past run.
Third occurrence: task 20260801-100108's Close-out claimed its positive
control produced "38 hits" when the command printed 42 -- inside the very task
promoting "probe, do not assert". Earlier ones mixed two units for one file
(33 comment lines vs 15 comment blocks) and shipped a 326-line count for a
file the same task had grown to 328.

The user picked the template option over skill prose (which is already what
the lesson says, and has now been read and violated three times) and over a
tool (the numbers that go wrong are ad-hoc, not from a fixed command set).

## Steps

1. Add the rule to the Close-out "Evidence" guidance in the `work` skill
   (`~/.claude/skills/work/`): a bare integer in a record must be adjacent to
   the command that printed it, with the unit named. Where a total is
   composed, paste the per-item breakdown so it is reconstructible rather than
   asserted.
2. Mirror it wherever `compound` describes RETRO/ledger numbers, so a count
   copied forward into a retro carries the same obligation.
3. Note the highest-risk position explicitly: a number in a Close-out written
   AFTER the last re-run (i.e. after review fixes) is stale by default -- the
   20260801-100108 case only became correct because the whole Evidence block
   was re-derived at the final tree state.

## Definition of Done

- [ ] Rule present in the `work` skill's Close-out/Evidence guidance
      (cmd: `grep -rn 'printed it' ~/.claude/skills/work/`)
- [ ] Rule present in the `compound` skill's record guidance
      (cmd: `grep -rn 'printed it' ~/.claude/skills/compound/`)
- [ ] Ledger entry marked PROMOTED, Pending promotions back to `None`
      (cmd: `grep -q 'record-numbers-from-a-rerun.*PROMOTED' LESSONS.md`)
- [ ] Tracker clean (cmd: `tatr check --ledger LESSONS.md`)

## Notes

- Skills live outside this repo, so the DoD proofs point at `~/.claude/skills`.
  The same shape as task 20260720-220050, which promoted process lessons into
  the global `~/AGENTS.md` and the flow skills.
- Keep it one rule, not a checklist. The lesson has failed on brevity three
  times; a longer template is not the fix.
