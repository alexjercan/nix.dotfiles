# Add a column and reflow check to the skills conformance gate

- STATUS: OPEN
- PRIORITY: 65
- TAGS: skills,tooling,docs
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

As a skill author, I want `check.sh` to fail on an over-long or ragged line in
the skill markdown, so a rewrap that leaves an orphan line is caught by the
gate instead of by a reviewer.

## Notes

- Promoted from `line-breaks-are-load-bearing` (x3): 20260730-154958,
  20260731-125123, 20260731-150849. The last occurrence was an 8-character
  orphan line left mid-paragraph by a one-line rewrap.
- Scope it to `home/modules/agents/skills/**.md`. `LESSONS.md` has ~10 lines
  over 80 columns (task-id lists), so a repo-wide rule would be red on
  arrival; decide whether the ledger is exempt or reformatted.
- A bare column cap does not catch the orphan itself - a short line before the
  paragraph's last is the actual defect. Decide at plan time whether the rule
  is column-only, or column plus a short-line-before-last heuristic, and state
  the false-positive cost of the second (tables, lists, and code fences).
- The rule needs an entry in the `RULES` inventory in
  `home/modules/agents/skills/check.sh` or `stale-rule-inventory` fires.
