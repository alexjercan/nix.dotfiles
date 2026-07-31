# Adopt tatr v2 and revalidate nix task history

- STATUS: OPEN
- PRIORITY: 50
- TAGS: feature, flow, tatr, migration, testing
- KIND: STORY
- FLOW STEP: PLANNED
- PLAN STATUS: APPROVED
- PARENT: 20260730-153122

## Story

As the nix.dotfiles maintainer, I want to adopt the completed tatr v2 release
and revalidate every local task and skill against it, so the deployed tool and
workflow finish the Epic in one coherent state.

## Steps

- [ ] Write the proof artifacts first: `tasks/20260730-155003/tatr-rev.py`
      (resolve the root `tatr` node through `flake.lock`'s root inputs map -
      NOT by node name, since `scufris` pulls a second, older `tatr` node - and
      compare it to `git -C /home/alex/personal/tatr rev-parse origin/master`),
      and confirm each DoD `cmd:` is red for the right reason on `master`.
- [ ] Confirm the adoption already landed rather than redoing it: `flake.lock`
      root `tatr` is `cd8b33d`, `~/.claude/skills/tatr/SKILL.md` equals
      `/home/alex/personal/tatr/skills/tatr/SKILL.md`, and the profile `tatr`
      exposes the v2 subcommands (`flow`, `frontier`, `context`, `claim`,
      `scaffold`, `proofs`, `ledger`). Record what was confirmed, not redone.
- [ ] Confirm the migration already landed: all 55 records under `tasks/`
      carry v2 `KIND`/`FLOW STEP`/`PLAN STATUS` fields, pre-Epic ones tagged
      `historical`, and `tatr check --ledger LESSONS.md` exits 0. Classify, do
      not invent, any record that still fails.
- [ ] Rewrite `tasks/20260730-153122/TASK.md` `## Done Means` onto proofs that
      still have a runner: drop criterion 5 (`test: parallel_lane_selection`,
      runner deleted with `skills/fixtures/` in 20260730-154955) and renumber
      6-7 to 5-6; restate criterion 4's "skill evaluation harness" clause as
      the manual read the `## Manual Acceptance` list already carries; leave
      criteria 1, 2, 3, 6 and 7 alone, naming
      `/home/alex/personal/tatr/checker.sh` as the file holding the
      `test_epic_frontier` and `test_ledger_pending_requires_disposition`
      runners so Finish can run them.
- [ ] Fold 20260731-104819 in: set its `STATUS: CLOSED` via `tatr edit`, and
      add a Notes line naming `tasks/20260730-155003/DECISION.md` as what
      superseded it. Its step "rewrite criterion 3, the fixture suite is gone"
      rested on a wrong premise - `test_epic_frontier` DOES still have a
      runner - so record that correction rather than acting on it.
- [ ] Update the Epic index: tick this Story in `## Child Tasks` with its
      close-out annotation, add this DECISION.md to `## Decisions`, and fold
      the lanes and retained-prototype acceptance the dropped and rewritten
      criteria used to carry into `## Manual Acceptance` so nothing is lost by
      the rewrite.
- [ ] Record `tasks/20260730-155003/VERIFICATION.md`: every canonical check
      with its command and exit code, the resolved tatr revision, the record
      count, and the two ledger entries already dispositioned PROMOTE.
- [ ] Note in the Epic that `tatr flow <epic> --to DONE` refuses while any
      child is not CLOSED (verified in a scratch repo: "child <id> is not
      CLOSED"), so open child 20260731-010900 must be resolved or dropped from
      the Epic before Finish. Do not resolve it here.

## Definition of Done

- The root `tatr` flake input resolves to the published tatr default-branch
  tip (cmd: `python3 tasks/20260730-155003/tatr-rev.py`).
- Every nix.dotfiles task and ledger passes v2 conformance
  (cmd: `tatr check --ledger LESSONS.md`).
- The Epic's acceptance criteria name no deleted fixture runner
  (cmd: `! grep -n "flow_v3_end_to_end\|parallel_lane_selection" tasks/20260730-153122/TASK.md`).
- Every `test:` proof the Epic still cites names a function that exists
  (cmd: `grep -n "^test_epic_frontier()\|^test_ledger_pending_requires_disposition()" /home/alex/personal/tatr/checker.sh`).
- 20260731-104819 is closed and names what superseded it
  (cmd: `grep -n "STATUS: CLOSED" tasks/20260731-104819/TASK.md && grep -n "20260730-155003" tasks/20260731-104819/TASK.md`).
- The Epic index ticks this Story
  (cmd: `grep -n "\[x\] 20260730-155003" tasks/20260730-153122/TASK.md`).
- The verification record names every canonical check with its result
  (cmd: `grep -c "exit=0" tasks/20260730-155003/VERIFICATION.md`).
- Skill and sprout integration suites pass
  (cmd: `bash home/modules/agents/skills/check.sh && bash home/modules/scripts/sprout-test.sh`).
- Flake evaluation passes (cmd: `nix flake check --no-build`).
- Representative final reports meet the agreed output budgets (manual: user
  approves them).

## Notes

- Parent Epic: 20260730-153122. Decision record: `DECISION.md` here.
- The external prerequisite is met: tatr `master` is published at `cd8b33d`,
  local and `origin/master` are level, and `flake.lock`'s root `tatr` input is
  already that revision (bumped in `495073f`). The old `4de04d5` node still in
  the lock belongs to `scufris`, not the root.
- Every canonical check was green on `master` at plan time: `tatr check`,
  `tatr check --ledger LESSONS.md`, `check.sh` (9 skills, 22 rules),
  `sprout-test.sh` (14/14), `nix flake check --no-build`. This cycle is record
  reconciliation, not adoption work; the DoD is written so each item is red on
  `master` only where a record actually needs changing.
- The dropped criterion 5 and the rewritten criterion 4 clause both keep their
  substance in the Epic's `## Manual Acceptance` list, which already carries a
  lanes item (20260730-154958) and a retained-prototype item (20260730-142540).
- `tatr proofs` reads `## Definition of Done`, not an Epic's `## Done Means`,
  so it returns nothing for 20260730-153122 and cannot serve as a proof there.
  This is why the Epic rewrite is proved by grep instead.
- Open question deferred to Finish, not to this task: 20260731-010900 is an
  open Epic child and will block `tatr flow 20260730-153122 --to DONE`.
