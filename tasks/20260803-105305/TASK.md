# Replace afk's agent-driven gates with tatr flow and sprout land probes

- PRIORITY: 65
- TAGS: afk, scripts, agents
- KIND: TASK
- ACTIVITY: WORKING
- GATES: PLAN
- RESOLUTION: -
- DEPENDS ON: 20260803-105234

Every approval gate in afk currently costs a resumed Claude session
(`gate`/`lifecycle_gate` in `home/modules/scripts/afk.sh`), and everything
that session does is mechanical: `tatr flow <id>` for the three lifecycle
gates, and the `landing.md` sequence for the last one. Replace those sessions
with code. An agent is only worth waking when the mechanical path refuses.

Both halves of the contract are now available. `tatr flow -n` is a real probe
as of tatr v1.0.1 (flake bumped from v1.0.0; task 20260803-105225 in
~/personal/tatr), and `sprout sync` / `sprout land -n` / the compound landing
message landed with task 20260803-105234 in this repo. Nothing blocks the
work.

## The new gate shape

Probe, execute, verify - the same three steps for every gate:

| gate | probe | execute |
| --- | --- | --- |
| NOTES_READY, PLAN_READY, WORK_DONE | `tatr -r <root> flow -n <id>` | `tatr -r <root> flow <id>`, then commit the task records |
| LAND_READY | `sprout sync -n <feature>` then `sprout land -n <feature>` | `sprout sync`, then `sprout land -m <subject> -m <body>` |

The existing postcondition checks (`require_gate`,
`require_activity_at_least`, the landed-commit and branch-gone checks) stay
and get stronger: afk now observes the transition instead of trusting a
session's marker.

A non-zero probe is not a failure of the run. Start a fresh `/flow <id>`
session with the unmet text appended to the prompt and let it resolve the
block, then re-probe.

## Consequences to handle

- `--resume` and `SESSION_UUID` can leave `run_claude` entirely: the fallback
  is a fresh session, and durable state is all a fresh `/flow` ever needed.
  Confirm nothing else depends on the resume path before removing it.
- Double advance: a session that ran `tatr flow` itself after emitting its
  marker leaves the cursor already at the target. Treat at-or-past as
  satisfied and skip the call rather than dying, which is what
  `require_activity`'s equality does today.
- afk inherits the task-record commit that `gates.md` currently asks the
  session for. It runs in the main checkout before WORKING and in the sprout
  worktree after, and `sprout land` refuses a dirty main checkout, so it
  cannot be skipped. Open question: a mechanical message
  (`docs: advance <id> to PLANNING`) or something better.
- The landing message comes from the task record that compound wrote; afk
  reads it and passes it to `land -m`. A missing message is a refusal, not a
  guess.
- No verification step after the sync: review already proved the branch, and
  the user checks the default branch after the run.

## Boundary

afk depends on the tatr and sprout contracts, not on the flow skill's prose.
The skills keep describing the gates for a human-driven `/flow`; afk must not
require them to change. See task 20260803-003849.

Cover the new gate paths in `home/modules/scripts/afk-test.sh`.

## Story

A run of `afk run <goal>` spends four sessions, not eight. Each one does a
phase and stops at its gate; afk answers the gate itself by probing tatr or
sprout, executing the transition, committing the task records, and re-checking
durable state. A session is woken only when a probe refuses, and it is woken
fresh, with the refusal text in its prompt.

## Steps

- [ ] Extract the sprout derivation so afk can depend on it. New
  `home/modules/scripts/sprout-pkg.nix`: a function taking `pkgs` and returning
  the `writeShellApplication` currently inline in `sprout.nix`. `sprout.nix`
  becomes `home.packages = [(import ./sprout-pkg.nix pkgs)]`; `afk.nix` adds
  the same import to `runtimeInputs`. No change to `sprout.sh`.
- [ ] Teach the test harness about sprout. In `afk-test.sh` `setup()`, write a
  `$TMP/bin/sprout` shim that execs `bash "$SCRIPT_DIR/sprout.sh" "$@"` (the
  path interpolated at write time), so the suite exercises the working tree's
  sprout and not the installed one. Add a `landing_message` fixture helper that
  appends a fenced `## Landing message` section to a RETRO.md, and export it
  through `fixtures.sh` alongside the others.
- [ ] Move worktree creation onto real sprout. Replace every manual
  `git worktree add -q -b feature/thing ... && git config --worktree
  sprout.task` block in `afk-test.sh` (`gen_work_to_land`, `gen_sprout_work`,
  `test_failure_paths`, `test_gate_resume_may_overshoot`) with
  `sprout new feature/thing --task "$id"`, so `sprout.target` is recorded and
  `sprout land` accepts the fixture.
- [ ] Renumber the fixtures for four sessions instead of eight. `gen_goal_cycle`
  drops its two inner gate side scripts and their replies; `gen_work_to_land`
  drops the review-gate and landing side scripts and emits two invocations;
  `gen_land` is deleted. The compound session now also calls `landing_message`.
  Update every invocation count and `argv_line` index in
  `test_run_goal_full_cycle`, `test_run_task_id_resumes`,
  `test_run_report_reads_as_a_report`,
  `test_session_header_names_the_claude_session_id`,
  `test_gate_resume_may_overshoot`, `test_token_limit_rotation` and the batch
  tests.
- [ ] Rewrite `test_argv_session_and_resume_policy` as
  `test_argv_every_session_is_fresh`: every invocation carries
  `--session-id` with a distinct UUID, no invocation carries `--resume`, and
  every invocation still carries the four fixed flags. The gate-label
  assertions go with the resume they described.
- [ ] Write the new tests red, before touching `afk.sh`:
  `test_gates_are_mechanical`, `test_refused_probe_wakes_a_session`,
  `test_gate_already_advanced_is_a_skip`,
  `test_landing_uses_sprout_and_the_recorded_message`,
  `test_landing_refuses_without_a_message`,
  `test_sync_conflict_wakes_a_session`,
  `test_landing_refuses_a_dirty_worktree`. Register each in the run list.
- [ ] Rewrite the `PROTOCOL` heredoc in `afk.sh`. The session summarizes the
  phase, reports the gate status and ends the turn; it must not perform the
  gate's own transition or landing, and must not commit the task records. It
  keeps running the transitions that belong to a PHASE - `review`'s APPROVE and
  `compound`'s close - so the instruction names the gate, not `tatr flow`.
- [ ] Drop the resume path from the driver. `run_claude` loses its `$1` mode
  parameter and its `--resume` branch, becoming
  `run_claude <session-uuid> <prompt>` that always passes `--session-id`.
  Delete `gate()`. Update both call sites.
- [ ] Add the mechanical gate helpers to `afk.sh`: `probe <root> <id>` running
  `tatr -r <root> flow -n <id>`, capturing stderr into `PROBE_TEXT` with ANSI
  stripped (`sed 's/\x1b\[[0-9;]*m//g'`); `commit_records <root> <id> <message>`
  doing `git -C <root> add tasks/<id>` then committing only when something was
  staged; `at_or_past <id> <kind> <value>` reusing `activity_rank` for
  `activity` and the `require_gate` token match for `gate`.
- [ ] Replace `lifecycle_gate` with `advance`, keeping its precondition
  equality and its postcondition floor. Order: `require_activity`, at-or-past
  skip, `probe`, `tatr flow`, `commit_records` with the message
  `docs: advance <id> to <ACTIVITY read back after the call>`, then
  `require_gate` / `require_activity_at_least`, then `report_phase` and
  `report_commits`. A refused probe returns non-zero having changed nothing.
- [ ] Replace the `LAND_READY` arm's `gate` call with the landing sequence:
  read `landing_message <root> <id>` from the RETRO.md fenced
  `## Landing message` block FIRST (a missing section or empty subject is a
  `die`), `commit_records <root> <id> "docs: close <id>"`, refuse a worktree
  still dirty after that commit, `sprout sync -n <feature>`, `sprout sync`,
  `sprout land -n <feature> -m <subject>`, then
  `sprout land <feature> -m <subject> -m <body>`. The landed-commit and
  branch-gone checks stay exactly as they are.
- [ ] Wire the refusal route in `run_item`. A refused probe or a refused sync
  sets `PENDING_UNMET`, prints a `gate` line saying a session is being woken,
  calls `require_progress` so two refusals with no change stop the run, and
  continues the loop. The next prompt is `/flow <id>` with the unmet text
  appended; `PENDING_UNMET` is cleared once used.
- [ ] Update the prose that describes the removed machinery: `afk.sh`'s file
  header comment (the `--resume` sentence), `usage()`'s gate paragraph if it
  still claims a session answers the gates, and `AGENTS.md` if its afk lines
  name the resume.
- [ ] Run the full suite, `nix flake check` and `tatr check` green.

## Definition of Done

- A goal run completes the whole cycle in four claude invocations, with afk
  performing the three lifecycle transitions and committing the records
  (test: `test_run_goal_full_cycle`, test: `test_gates_are_mechanical`).
- Every claude invocation is a fresh session; none resumes
  (test: `test_argv_every_session_is_fresh`).
- A refused `tatr flow -n` is not a run failure: afk wakes a fresh `/flow`
  whose prompt carries the ANSI-free unmet text
  (test: `test_refused_probe_wakes_a_session`).
- A session that already performed the transition leaves afk skipping the
  execute rather than dying (test: `test_gate_already_advanced_is_a_skip`).
- Landing runs `sprout sync` then `sprout land` with the subject and body from
  RETRO.md `## Landing message`, and still proves the commit landed and the
  branch is gone (test: `test_landing_uses_sprout_and_the_recorded_message`).
- A missing or empty `## Landing message` stops the run before any sync
  (test: `test_landing_refuses_without_a_message`).
- A conflicting sync wakes a session instead of failing the run
  (test: `test_sync_conflict_wakes_a_session`).
- A worktree still dirty after the record commit refuses the land
  (test: `test_landing_refuses_a_dirty_worktree`).
- Every existing postcondition still bites - wrong activity, missing NOTES.md,
  an ineffective approval, an unlanded branch, a half-landing
  (test: `test_failure_paths`).
- The injected protocol no longer asks the session to transition or commit
  (cmd: `grep -n 'The runner performs the transition' home/modules/scripts/afk.sh`).
- afk's package has sprout on its runtime PATH
  (cmd: `grep -n 'sprout-pkg.nix' home/modules/scripts/afk.nix`).
- The whole runner suite is green (cmd: `bash home/modules/scripts/afk-test.sh`).
- Repository checks pass (cmd: `nix flake check`, cmd: `tatr check`,
  cmd: `bash home/modules/scripts/sprout-test.sh`).

## Notes

- Confirmed on base: `tatr flow -n` writes `Task <id> would move A -> B` to
  stdout and the `ERROR: ...` refusal plus `  - <message>` lines to stderr,
  exiting 1; a legal edge exits 0 (tatr 1.0.1). The ERROR label is colored
  unconditionally, so `PROBE_TEXT` must be ANSI-stripped before it reaches a
  prompt or an assertion.
- Confirmed on base: `bash home/modules/scripts/afk-test.sh` is green at 19
  tests; none of the new test names exists yet.
- `sprout land`'s cleanup calls `tmux kill-session ... || true`, so the suite
  needs no tmux; `resolve_target` falls back to the main checkout's branch, so
  a fixture worktree without `sprout.target` would still land - `sprout new` is
  used anyway because it is the path production takes.
- Three lifecycle transitions belong to afk (UNDERSTANDING -> PLANNING,
  PLANNING -> WORKING via the PLAN gate, WORKING -> REVIEWING). The transitions
  inside `review` and `compound` belong to those phases and stay with the
  session; the PROTOCOL must not forbid them.
- Decision: no re-verification between `sprout sync` and `sprout land`.
  `landing.md` step 2 asks a human-driven flow to re-verify; afk deliberately
  skips it, because review already proved the branch and the user inspects the
  default branch after a run. Recorded, not omitted.
- The renumbering of `afk-test.sh` invocation indices is the largest mechanical
  risk in the task; it is its own Step for that reason.
- Nothing under `home/modules/agents/skills/` changes. The gates keep their
  prose for a human-driven `/flow`; that boundary is task 20260803-003849.
- Assumption: a phase session leaves its records uncommitted at the three
  lifecycle gates, so `commit_records` has something to stage. `compound`
  commits its own retro, which is why `commit_records` is a no-op when the add
  stages nothing.
