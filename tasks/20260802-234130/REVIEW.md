# Review: afk run accepts a batch of goals or task IDs and runs them sequentially

- TASK: 20260802-234130
- BRANCH: feat/afk-run-batch

## Round 1

- REVIEWER: out-of-context
- VERDICT: APPROVE

- [ ] R1.1 (MINOR) home/modules/scripts/afk.sh:915 - `BATCH_REMAINING` is
  built with `${*:index+1}`, which space-joins the arguments. For a batch of
  goal strings (`afk run "fix the parser" "add tests"`) a stop prints
  `not started: add tests`, and re-issuing that verbatim starts two goals
  instead of one. The line exists to be re-issued, so join with
  `printf ' %q' "${@:index+1}"` instead.
  - Response:
- [ ] R1.2 (MINOR) home/modules/scripts/afk-test.sh:266 - `seed_working_task`
  retries `tatr new` forever with stderr discarded. It recovers from the
  same-second ID collision it was written for, but any other `tatr new`
  failure turns a red suite into a suite that never terminates. Bound the loop
  (e.g. 5 attempts) and fail with the captured stderr when it is exhausted.
  - Response:
- [ ] R1.3 (MINOR) home/modules/scripts/afk-test.sh:1184 - Step 2's per-item
  elapsed time is unpinned: deleting `item_started` in `run_item` and printing
  `$SECONDS` again leaves all 18 tests green, because every item in the suite
  finishes inside the same second. `test_run_batch_runs_each_in_turn` already
  has `reply_slow` available - delay item 1 past a second boundary and assert
  item 2's own summary still reads `0m00s` while the batch total does not.
  - Response:
- [ ] R1.4 (NIT) home/modules/scripts/afk.sh:887 - `ITEM_SESSIONS` is the only
  global in this file with no declaration or comment at file scope; every
  other one (`BATCH_REMAINING`, `CLAUDE_PID`, `KILL_REASON`, `SESSION_TOKENS`)
  is declared and explained where it is introduced. Declare it next to
  `BATCH_REMAINING` with a one-line note that `run_item` writes it and
  `cmd_run` reads it.
  - Response:
- [ ] R1.5 (NIT) tasks/20260802-234130/TASK.md:158 - the close-out says
  `gen_work_to_land` has "fifteen" call sites; there are eighteen. All of them
  are correctly updated, so only the number is wrong - say eighteen.
  - Response:

Verified independently, from the worktree:

- `bash home/modules/scripts/afk-test.sh` - 18 passed, 0 failed.
- `bash home/modules/agents/skills/check.sh` - clean, 8 skills, 23 rules.
- `nix flake check` - all 6 checks passed.
- `tatr check` - clean.
- `bash home/modules/scripts/afk.sh help | grep -qF 'run <goal|task-id>...'` -
  exit 0.
- `shellcheck -s bash home/modules/scripts/afk.sh` - clean.
- Re-derived `${*:index+1}` in an isolated function: `a b c` yields `b c`,
  `c`, then empty, and a single argument yields empty on its only pass. The
  claim that the last item and a one-argument run both leave
  `BATCH_REMAINING` empty holds, so `report_remaining` adds no line there.
- Re-derived the docs sweep: outside `tasks/` (exempt as append-only), the
  only `afk run` / `AFK_MAX_SESSIONS` mentions are in `usage()` itself, both
  updated. `AGENTS.md`'s afk rule is about the shared marker vocabulary, which
  this diff does not touch, so deferring it is correct.
- Re-derived the "single `cd`" claim: `grep -n 'cd ' afk.sh` returns exactly
  one hit, in `cmd_run` before the loop, so item N+1 cannot inherit a working
  directory from item N's landing.
- Re-derived every ticked Step against the diff; all fourteen are delivered as
  written, including the `run_item`-local `prev_fp` that Step 1 calls out.
- Could not verify by execution that a real multi-goal batch behaves as the
  sandbox scripts it; the shim is the only rig available.

- Process signal: Step 8 estimated three `gen_work_to_land` call sites and the
  real number was eighteen, and the plan did not foresee that seeding two
  tasks in one sandbox collides on `tatr`'s second-resolution IDs. Both were
  absorbed inside the step rather than becoming new work, but they are the
  kind of fixture-scale surprise a plan step could have sized by grepping the
  call sites first.

No `manual:` proofs are open on this task; every criterion in the Definition
of Done is a `test:` or `cmd:` proof and all of them were rerun above.
