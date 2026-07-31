# Review: State YAGNI and KISS in the global rules, plan scope gate, and review dimensions

- TASK: 20260731-150849
- BRANCH: feature/yagni-kiss-rules

## Round 1

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

- [x] R1.1 (MAJOR) tasks/20260731-150849/TASK.md:7 - the branch record still
  reads `FLOW STEP: PLANNED` / `STATUS: OPEN` while the work is committed with
  a full close-out. The transitions were run against the MAIN checkout, so
  master carries an uncommitted `FLOW STEP: REVIEWING` for a task whose record
  lives on this branch. Restore the main checkout's copy
  (`git checkout HEAD -- tasks/20260731-150849/TASK.md` from
  /home/alex/personal/nix.dotfiles), then re-run the transitions against the
  worktree (`tatr -r <worktree> flow 20260731-150849 --to WORKING` and
  `tatr -r <worktree> flow 20260731-150849`) and commit the marker on the
  branch.
  - Response: fixed in this round's fix commit. The main checkout was
    restored with
    `git checkout HEAD -- tasks/20260731-150849/TASK.md` (it is clean again at
    `FLOW STEP: PLANNED`, matching master's HEAD), and
    `tatr -r <worktree> flow 20260731-150849 --to WORKING` moved the BRANCH
    record to WORKING; this round's hand-back moves it to REVIEWING. Every
    remaining transition for this task runs against the worktree.
- [x] R1.2 (NIT) home/modules/agents/skills/review/dimensions.md:45 - the
  merged line is 87 chars against the file's ~80-col wrap. Rewrap so line 45
  ends `... architectural choice a` with `cold reader` starting line 46.
  - Response: fixed in this round's fix commit. Rewrapped; `awk 'length>80'`
    over
    `dimensions.md` and `lanes.md` now reports nothing.
- [x] R1.3 (NIT) home/modules/agents/skills/review/lanes.md:14 - the Design
  lane's lens summary still reads `conventions, reuse, complexity, decision
  records, invalidated documentation`, so a lane reviewer is never told to
  hunt the new finding class. Change `complexity` to `scope/YAGNI,
  complexity`.
  - Response: fixed in this round's fix commit. The Design lane now reads
    `conventions, reuse,
    scope/YAGNI, complexity, decision records, invalidated documentation`;
    `lanes.md` is 178 of 600 words.

Severity note: the out-of-context reviewer filed R1.1 as MINOR. Raised to
MAJOR by the in-session pass - the divergence is not cosmetic. `sprout land`
squash-merges only tracked branch content, so landing as-is would write
`PLANNED` over master's marker while an uncommitted `REVIEWING` sits in the
main checkout, and the same defect class (`edit-the-worktree-not-the-cwd`)
already cost this repository two GOAL ticks committed from the wrong repo.

Re-derived by the in-session pass (not taken on the reviewer's word):

- The marker divergence itself: `git status --porcelain` in the main checkout
  shows ` M tasks/20260731-150849/TASK.md`, whose copy reads `IN_PROGRESS` /
  `REVIEWING`, against the branch copy's `OPEN` / `PLANNED`.
- `review/lanes.md:14` read directly; the Design lane summary is as quoted.
- The 87-character line confirmed with `awk 'length>80'` over
  `dimensions.md`; it is the only line in the file over 80.
- Proofs 1, 2 and 3 re-run from the worktree: all exit 0, `check.sh` clean
  (9 skills, 22 rules, 179 flow-family description words).

The reviewer's own verification (four proofs green, literal Steps against the
diff, close-out numbers recomputed, doc sweep, no DECISION.md owed) is
recorded here as context, not as a finding. No `manual:` proofs exist, so
nothing is pending on the user.

## Round 2

- REVIEWER: out-of-context
- VERDICT: APPROVE

- [ ] R2.1 (NIT) home/modules/agents/skills/review/dimensions.md:47 - the R1.2
  rewrap left an orphan 8-char line holding only the word `decision`, between
  two 77-char lines. Rejoin it: line 46 should end `... and that a decision`
  and line 47 begin `changing an earlier one carries ...`, then reflow lines
  46-49 so each sits under 80 chars with no short line before the paragraph's
  last.
  - Response:

R1.1, R1.2 and R1.3 are ticked on the round-1 reviewer's own confirmation.

- R1.1 CONFIRMED: the branch record reads `IN_PROGRESS` / `REVIEWING`,
  committed in `9396683` and `5451169`; `git status --porcelain` in the main
  checkout is empty, so the stray uncommitted marker is gone. The reviewer
  accepted the escalation to MAJOR and stated why its own MINOR was low: it
  had checked only the branch record and never diffed the main checkout.
- R1.2 CONFIRMED with the caveat filed as R2.1: no line in `dimensions.md` or
  `lanes.md` exceeds 80 chars, but the rewrap left the orphan.
- R1.3 CONFIRMED: `lanes.md:14-15` names `scope/YAGNI` in the Design lane.

Regression sweep for the fix commits: all four proofs re-run from the worktree
exit 0 (`check.sh` clean at 9 skills / 22 rules / 179 description words;
`sprout-test.sh` 14 passed, 0 failed; `tatr check --ledger LESSONS.md` 0;
`nix flake check` all checks passed). Doc sweep re-run: zero hits for
`More code` or `needless complexity` outside `.git` and `tasks/`. Budgets:
`dimensions.md` 506/600, `lanes.md` 178/600 (the lens edit cost 2 net words).
The fix commits touched only the four expected files.

R2.1 is a NIT, so it does not block APPROVE; per the verdict rule a NIT-only
round cannot be REQUEST_CHANGES. It is left open here and applied as a
recorded cleanup in the compound commit rather than fabricating a third round
to carry one reflow. No `manual:` proofs exist, so nothing is pending on the
user.
