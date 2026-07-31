# Rewrite the flow-suite v3 Epic Done Means onto runnable proofs

- STATUS: OPEN
- PRIORITY: 70
- TAGS: chore,tatr,skills
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

As the Epic's owner, I want its Done Means to name proofs that still have a
runner, so the Epic can be closed on evidence rather than on assertion.

## Steps

- [ ] Rewrite criterion 3 (test: `test_epic_frontier`): the fixture suite is
      gone, so restate it as the `tatr frontier <epic-id>` command whose output
      shows an unblocked child, or as a manual read of the Epic index.
- [ ] Rewrite criterion 5 (test: `parallel_lane_selection`): restate as a grep
      proving `plan/lanes.md` and `review/lanes.md` state the lane-selection
      rule, or as a manual item.
- [ ] Rewrite criterion 4's "skill evaluation harness" clause, which named the
      same removed harness.
- [ ] Confirm criteria 1, 2, 6 and 7 still run, and leave them alone if so.
- [ ] Re-run `tatr check` on the Epic.

## Definition of Done

- Every `## Done Means` proof on 20260730-153122 runs and passes, or is an
  explicit `manual:` item (cmd: `tatr proofs 20260730-153122`).
- The Epic record lints clean (cmd: `tatr check 20260730-153122`).

## Notes

- Raised as R2.2 in tasks/20260730-154955/REVIEW.md. Deleting
  `home/modules/agents/skills/fixtures/` removed the runner for the fixture
  names the Epic's Done Means cite.
- Kept out of 20260730-154955 deliberately: editing the parent Epic's
  acceptance criteria from inside a child Story's diff widens that task past
  one cohesive change.
- Do this BEFORE the Epic's Finish, since Finish verifies each criterion.
