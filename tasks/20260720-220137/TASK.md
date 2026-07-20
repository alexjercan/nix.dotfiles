# retro-completeness: mark pre-flow (Jul 3/4) tasks historical

- STATUS: OPEN
- PRIORITY: 30
- TAGS: chore

## Story

As the maintainer, I want the pre-flow tasks that predate retrospectives (the
~10 July-3/4 tasks with REVIEW but no RETRO) marked historical, so that
`tatr check -S` stops flagging them without fabricating fake retros for work
whose context is long gone.

## Steps

- [ ] Identify the CLOSED tasks lacking RETRO.md (predate compound-skill adoption).
- [ ] Apply the historical marker (per tatr task #5's mechanism) to each.
- [ ] Confirm `tatr check -S` is clean afterward.

## Definition of Done

- Pre-flow tasks no longer flag under strict check (cmd: `tatr check -S`).
- No fabricated retros were added (manual: reviewer confirms only markers changed).

## Notes

- Depends on tatr task #5 (historical/no-retro recognition in `tatr check`).
