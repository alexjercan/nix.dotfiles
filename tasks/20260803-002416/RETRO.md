# Retro: make round-1 review unconditionally out-of-context and survive a gate overshoot in afk

- TASK: 20260803-002416
- BRANCH: feature/afk-gate-overshoot
- REVIEW ROUNDS: 1

## What went well

- Planning corrected the Story before any code. The Story asserted the PLAN
  gate was broken the same way; the Notes' scratch check found `PLAN_READY`'s
  postcondition is `require_gate`, a token match on an accumulating field, so
  only `WORK_DONE` was ever an equality. The plan kept the generalized helper
  and downgraded the PLAN case to a regression pin rather than dropping it -
  the right call, since a future `activity` postcondition lands there.
- Every DoD proof named its own red-on-base evidence, including the two traps:
  grepping `PROTOCOL` for `ROTATE` alone would have passed on base because the
  status list already prints that word, and the hatch grep named its 3
  expected base matches. Round 1 re-derived both on `master` and they held.
- The failure was reproduced as a test before the fix. Reverting the
  `activity)` arm to `require_activity` fails exactly the two tests that
  encode the behaviour and nothing else.
- Round 1 ran in a genuinely fresh context. The `WORK_DONE` gate stopped at
  the cut, and a `/flow` session that had never seen the implementation did
  the review - the very discipline this task exists to make unconditional.

## What went wrong

- Narrowing `- REVIEWER:` in `rounds.md` left `SKILL.md` step 5 pointing at an
  exception a later round can no longer elect (R1.1). DECISION.md #3
  deliberately kept step 5 and reworded the field in the same task, but the
  two were decided separately and never read against each other. The decision
  seemed sound because each half is defensible alone: round 1 unconditional,
  later rounds by default. Only the field's vocabulary ties them.
- The three new test generators duplicate `gen_work_to_land`'s blocks instead
  of being extracted from it (R1.2), and the close-out described them as
  "factored out", which overstates what happened. Two have a single caller.
- `gen_land` hardcodes the worktree path its siblings take from `$WT_REL`
  (R1.3), because its heredoc is quoted and the reason is not written down.

## What to improve next time

- When a task narrows a field's allowed values, grep every rule that elects
  one and re-read it in the same pass. `review/dimensions.md` already asks for
  exactly that sweep after a contract edit; the sweep ran across files (it
  correctly found nothing outside `review/`) but not across rules inside the
  two files being edited. Cross-reference sweeps have to include the diff's
  own files.
- Copying an existing fixture's shape is the moment to call it instead. Three
  near-duplicate generators is cheaper to notice at write time than after a
  review round.

## Action items

- R1.1, R1.2 and R1.3 are open MINOR/NIT findings, non-blocking. Fold them
  into the next `afk`/skills task rather than reopening this one.
- No context pressure was measured or recorded. The `WORK_DONE` handoff was
  the only context cut, and it worked.
- Knowledge: the floor-not-equality lesson was submitted centrally.
