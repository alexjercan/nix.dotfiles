# afk run accepts a batch of goals or task IDs and runs them sequentially

- PRIORITY: 0
- TAGS: afk, scripts
- KIND: TASK
- ACTIVITY: PLANNING
- GATES: -
- RESOLUTION: -

`afk run` takes exactly one argument today, so a person supervising an
unattended session has to sit and wait for each goal to land before typing the
next one. Make `run` accept one or more arguments and drive them one after the
other, each through the full flow cycle it already implements.

Nothing about a single item's lifecycle changes: the same session loop, the
same gate resumes, the same tatr and git cross-checks. What is new is the
queue around them, the up-front validation of the whole queue, and the batch
summary at the end.

## Steps

- [ ] Extract the per-item driver in `home/modules/scripts/afk.sh`. Move the
      body of `cmd_run` - the `goal`/`task` head line, the session loop and
      the trailing `done <id> landed` plus `N sessions, XmYYs` summary - into
      `run_item()`, taking one goal-or-ID argument. Leave the run-level `afk`
      and `repo` head lines in `cmd_run`. `require_progress` reads `prev_fp`
      from its caller's scope, so `run_item` must declare `local prev_fp=""`;
      confirm the existing suite still passes before going further.
- [ ] Make the per-item elapsed time item-local. The summary line reads
      `$SECONDS`, which is process-wide and only coincides with the item's
      duration for the first item; record the value of `$SECONDS` when
      `run_item` starts and report the difference.
- [ ] Make `cmd_run` accept 1..N arguments. Reject zero arguments and any
      empty argument, `cd "$main_worktree"` once, then validate the whole
      queue before starting: every argument matching `^[0-9]{8}-[0-9]{6}$`
      must pass `task_exists`. A typo in the third argument must not be
      discovered after the first two have landed.
- [ ] Loop `run_item` over the arguments in order, resetting `TASK_ID` per
      item (it is a global read by `gate` and `lifecycle_gate`).
- [ ] Report the queue on a stop. Keep the not-yet-started arguments in a
      `BATCH_REMAINING` global, and have `die` and `on_signal` print
      `not started: <args>` when it is non-empty, so a batch that stops
      halfway does not lose what it had left to do. `die` also runs before
      any queue exists (bad argument count, no git repository); an empty
      `BATCH_REMAINING` must add no line.
- [ ] Add the batch summary. After the loop, when more than one argument was
      given, print a `batch  N tasks landed` head line with the total session
      count and total elapsed time. With one argument the report stays
      byte-identical to today's.
- [ ] Update `usage()`: `run <goal|task-id>...`, sequential execution, the
      stop-at-the-first-failure policy, and `AFK_MAX_SESSIONS` counting per
      item rather than per run.
- [ ] Parameterize `gen_work_to_land` in `home/modules/scripts/afk-test.sh`
      with the task ID so two different tasks can be scripted in one sandbox.
      Its side scripts read `$AFK_TEST_TMP/task_id` at run time, which is a
      single slot; take the ID as an argument and interpolate it, escaping the
      runtime variables (`\$REPO`, `\$XDG_CACHE_HOME`) that must not expand at
      generation time. Update its three call sites.
- [ ] Add `test_run_batch_runs_each_in_turn`: two seeded WORKING tasks, both
      driven to landing. Assert exit 0, both records resolved DONE, the run
      header printed once, item 1's `done` line before item 2's prompt, a
      per-item summary each, and the batch summary. Both items may reuse the
      `feature/thing` branch name - item 1's landing deletes it - which is
      itself the leakage check.
- [ ] Add `test_run_batch_stops_at_the_first_failure`: item 1 ends BLOCKED.
      Assert non-zero, the remaining argument named as not started, no
      invocation for item 2, and item 2's record untouched.
- [ ] Add `test_run_batch_validates_every_argument_up_front`: a good ID
      followed by `19990101-000000`. Assert non-zero, the bad ID named, and
      zero claude invocations.
- [ ] Update `test_usage`: `run with two arguments fails` no longer holds -
      replace it with an empty-argument rejection and a check that `help`
      documents the batch form. Register the three new tests at the bottom of
      the file.
- [ ] Decide whether `AGENTS.md` needs a line: the batch changes afk's
      command surface but no skill label, shared marker status or check-suite
      entry. Update it, or defer with the reason recorded here.
- [ ] Run the canonical checks: `bash home/modules/scripts/afk-test.sh`,
      `bash home/modules/agents/skills/check.sh`, `nix flake check`,
      `tatr check`.

## Definition of Done

- `afk run <a> <b>` drives `<a>` to a landed commit, then `<b>`, each with its
  own phase report and summary. (test: `test_run_batch_runs_each_in_turn`)
- A one-argument run prints no batch summary, so today's report is unchanged.
  (test: `test_run_batch_runs_each_in_turn`)
- A batch stops at the first item that fails and names the arguments it never
  started. (test: `test_run_batch_stops_at_the_first_failure`)
- Every task-ID argument is verified before the first Claude session runs.
  (test: `test_run_batch_validates_every_argument_up_front`)
- `afk help` documents the batch form. (cmd: `bash
  home/modules/scripts/afk.sh help | grep -qF 'run <goal|task-id>...'`)
- The afk suite is green. (cmd: `bash home/modules/scripts/afk-test.sh`)
- The skills gate is green. (cmd: `bash home/modules/agents/skills/check.sh`)
- The flake checks are green. (cmd: `nix flake check`)
- The task records lint clean. (cmd: `tatr check`)

## Notes

- Base-branch red confirmed: `bash home/modules/scripts/afk.sh run a b` exits
  1 with `run takes exactly one argument`.
- `home/modules/scripts/afk.nix` only wraps the script with
  `writeShellApplication`; no change expected there.
- Ownership: this touches only `afk.sh` and `afk-test.sh`. No skill text, no
  marker vocabulary, no gate label, so the docs-sync rule in `AGENTS.md`
  ("Skills are a doc surface") does not fire.
- Fail-fast, not continue-on-error: every existing stop in afk means durable
  state disagreed with what a session claimed, and running the next goal on
  top of that is exactly what afk is built to refuse. Recorded in DECISION.md
  with the alternative.
- The session counter and `AFK_MAX_SESSIONS` are per item, not per batch: the
  bound exists to catch one task going nowhere, and a shared budget would
  starve the last item of a long batch.
- Duplicate arguments are not rejected. Re-running a task already resolved
  DONE is a near no-op through the existing `DONE`/`LAND_READY` routes, so
  deduplication would be a guard with no failure to prevent.
