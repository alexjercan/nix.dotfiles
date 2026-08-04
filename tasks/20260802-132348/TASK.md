# Add an unattended afk flow runner

- PRIORITY: 80
- TAGS: feature, agents, flow, claude
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE

## Story

Add a small `afk` CLI, packaged like `sprout`, that runs this repository's
`/flow` skill through headless Claude Code. `afk run "<goal>"` and
`afk run <task-id>` automatically accept the standard flow gates, rotate to a
fresh Claude session at every requested context cut, and continue through
landing without routine user input.

## Steps

- [x] Add `home/modules/scripts/afk-test.sh`: the sandbox harness modelled on
      `sprout-test.sh` (hermetic git, one mktemp repo per case, `check`/`not`/
      `str_contains` helpers) plus a fake `claude` shim placed first on `PATH`
      that appends its argv to `$TMP/argv.log` and replays a per-case
      stream-json fixture from `$TMP/replies/<n>.jsonl`.
- [x] Add `home/modules/scripts/afk.sh` with `run`/`help` usage, main-worktree
      resolution copied from `sprout.sh`, goal-vs-task-ID input detection
      (`^[0-9]{8}-[0-9]{6}$`), and the `AFK RUN START` / `REPO` / `GOAL` or
      `TASK` audit header.
- [x] Implement one Claude invocation in `afk.sh`: `uuidgen` session ID,
      `CREATE CLAUDE SESSION <uuid>`, `claude -p --output-format stream-json
      --verbose --dangerously-skip-permissions --disallowed-tools
      AskUserQuestion --session-id <uuid> --append-system-prompt <protocol>
      "/flow ..."`, consumed by a `read -t "$AFK_HEARTBEAT_SECS"` loop that
      prints audit lines and captures the terminal `result` event; a missing
      `result`, `is_error: true`, or a nonzero exit is fatal.
- [x] Implement control routing in `afk.sh`: parse the trailing
      `AFK <STATUS> <id>` marker, cross-check `<id>` and FLOW STEP against
      `tatr show`, answer `PLAN_READY` / `WORK_DONE` / `LAND_READY` with a
      single `--resume <uuid>` turn carrying the exact `gates.md` label, verify
      the resulting FLOW STEP (or landed commit) before rotating, start a fresh
      session for `ROTATE`, print the summary for `DONE`, and exit nonzero for
      `BLOCKED`, unknown, or state-inconsistent markers.
- [x] Implement the stop policy in `afk.sh`: a durable-state fingerprint (FLOW
      STEP, main HEAD, feature HEAD, worktree dirty hash, latest review
      verdict), stop on two identical consecutive worker fingerprints, bound
      rotations with `AFK_MAX_SESSIONS`, and trap INT/TERM to kill only the
      recorded Claude PID and exit with its status.
- [x] Package it: `home/modules/scripts/afk.nix` wrapping `afk.sh` with
      `pkgs.writeShellApplication` (runtimeInputs git, jq, coreutils,
      util-linux, claude-code) and import it from
      `home/modules/scripts/default.nix`.
- [x] Re-read the runner, packaging and tests; add `afk-test.sh` to the check
      suite list in `AGENTS.md`; record the final design tradeoffs and
      verification in this task and in `DECISION.md`.

## Definition of Done

- `afk run "<goal>"` drives a scripted goal run from task creation through
  landing, and `afk run <task-id>` resumes from durable task state without
  re-creating a task. (test: `test_run_goal_full_cycle`,
  `test_run_task_id_resumes`)
- Every fresh invocation prints `CREATE CLAUDE SESSION <uuid>`, and the audit
  log carries flow statuses, `AUTO_APPROVE`, commits, landing and the final
  `GOAL DONE` / `AFK RUN COMPLETE` summary in execution order.
  (test: `test_audit_log_order`)
- Every Claude argv contains `--dangerously-skip-permissions`; ordinary
  continuation passes a fresh `--session-id` and never `--resume`, while
  `--resume <uuid>` appears exactly once per gate carrying the exact approval
  label. (test: `test_argv_session_and_resume_policy`)
- The runner exits nonzero on a Claude error result, a heartbeat stall, an
  unknown or missing control marker, a gate approval that did not produce its
  required FLOW STEP, and an unlanded branch after `LAND_READY` approval.
  (test: `test_failure_paths`)
- On SIGINT the runner kills only the recorded Claude PID, exits nonzero, and
  leaves the task record unchanged for a later `afk run <task-id>`.
  (test: `test_interrupt_kills_recorded_pid`)
- Repeated worker sessions that leave the durable-state fingerprint unchanged
  stop the run instead of rotating forever.
  (test: `test_no_progress_fingerprint_stops`)
- `afk` is a home-manager package built from `afk.sh`.
  (cmd: `test -x "$(nix build --no-link --print-out-paths .#homeConfigurations.alex.config.home.path)/bin/afk"`)
- Repository checks pass. (cmd: `bash home/modules/scripts/afk-test.sh && bash home/modules/scripts/sprout-test.sh && bash home/modules/agents/skills/check.sh && tatr check && nix flake check`)

## Notes

- Design discussion and audit-output example: `NOTES.md`. Load-bearing choices:
  `DECISION.md`.
- Keep the runner flow-specific. Do not import Scufris's web, database, MCP,
  authentication, concurrency, or general agent-registry layers.
- Verified against Claude Code 2.1.220: `--session-id`, `--resume`,
  `--append-system-prompt`, `--disallowed-tools`, `--dangerously-skip-permissions`
  and `--output-format stream-json --verbose` all exist. A probe run showed the
  terminal event is `{"type":"result","subtype":"success","is_error":true,...}`
  for a rate limit, so `subtype` alone is not an error test - check `is_error`
  and the process exit status. Transcripts live at
  `~/.claude/projects/<escaped-cwd>/<session-id>.jsonl`, which is how a resume
  target's existence is checked.
- The account is weekly-rate-limited right now, so no end-to-end run against
  real Claude is possible during this task; the fake-`claude` integration test
  is the whole automated proof, and a real run stays a later manual check.
- `sprout-test.sh` is not wired into `nix flake check`; `afk-test.sh` follows
  that precedent and stays a hand/AGENTS.md-listed check.
- Assumption: `claude -p "/flow <id>"` resolves the repository skill, and the
  flow skill's gate question surfaces as an ended turn plus the injected
  marker once `AskUserQuestion` is denied. Confirm in Step 3 with a real
  single-session probe once the rate limit resets, before trusting a full run.

## Close-out

### What and why

`afk` is one bash file (`home/modules/scripts/afk.sh`, ~480 lines) plus a
`writeShellApplication` wrapper and a 700-line integration test, matching the
`sprout` shape exactly. `afk run "<goal>"` or `afk run <task-id>` supervises a
chain of DISPOSABLE headless Claude sessions: every ordinary continuation is a
brand-new `--session-id` session running `/flow <id>` (the `/clear` equivalent),
and `--resume` is spent only on completing one approval transaction with the
literal label from `flow/gates.md`.

The load-bearing choice inside the runner is that the injected
`AFK <STATUS> <id>` marker only ROUTES; it never asserts. Every branch it
selects is checked against `tatr show` and `git` before and after acting: a
gate is refused unless the task is in the FLOW STEP that gate is legal from,
and refused again unless the approval actually produced the next step (or, for
landing, a new commit on the default branch AND a deleted feature branch).
`sabotage` runs confirmed each of those checks is the only thing standing
between a green suite and a wrong routing decision.

### Deviations from the plan

- Step 6 listed runtimeInputs "git, jq, coreutils, util-linux, claude-code",
  but Step 4 requires cross-checking against `tatr show`, so `pkgs.tatr` (from
  the existing flake input's overlay) is in `runtimeInputs` too. Worktree
  discovery deliberately does NOT shell out to `sprout`: the association is a
  plain `git config --worktree sprout.task` read, so afk depends on git alone
  for it and `sprout` stays out of the closure.
- The plan's audit example implied scraping Claude's prose for `FLOW ...`,
  `COMMIT ...` and `CHECKS PASS` lines. The runner derives all of them from
  `tatr` and `git` instead. Scraped audit lines would be the model's claims;
  derived ones are what actually happened, which is the same principle that
  makes the marker advisory.
- The gate resume is not required to emit a marker (state is the authority);
  if it emits one, its task ID must still match.

### Difficulties and diagnosis

`test_interrupt_kills_recorded_pid` failed for a long while in a way that
looked like the runner nuking its whole process group: the "unrelated
process survives" assert failed and no `INTERRUPTED` line appeared. Two
independent shell facts, both reproduced in isolation before touching the
runner:

1. A background job in a NON-INTERACTIVE shell inherits SIGINT ignored, and an
   ignored signal cannot be trapped. The runner never saw the signal at all;
   the run simply continued to its natural end, by which time the 20s bystander
   `sleep` had expired on its own. Fix: `set -m` around the launch, which gives
   the job its own process group and default dispositions - the same situation
   a real terminal run has.
2. `afk run ... &` through the test's `afk()` helper backgrounds a SUBSHELL, so
   `$!` is the subshell, not the runner whose trap is under test. Fix: launch
   `bash "$AFK"` directly there.

A third, related property is worth writing down because it shaped the runner:
bash defers a trap until the current foreground command finishes. afk blocks in
`read -t` (a builtin, interruptible), so its handler runs promptly; had it
blocked in a plain `wait` on the child, the trap would have been delayed until
Claude exited on its own.

One real bug was found by the `!`-swallows-`$?` trap: `if ! read -t ...; then
rc=$?` records the status of the NEGATION, not of `read`, so the heartbeat
timeout (>128) was indistinguishable from a clean EOF and stalls were misreported
as "no terminal result event". The status is now captured on its own line.

### Evidence

- `bash home/modules/scripts/afk-test.sh` - 8 cases, ~13s, all green. It
  covers both DoD run shapes, the audit ordering, the argv session/resume
  policy, ten failure paths, the interrupt, and the no-progress stop.
- Sabotage runs (each reverted): dropping `--resume`, the fingerprint stop, the
  heartbeat, the trap's kill, the marker requirement, the pre-gate and post-gate
  FLOW STEP checks, the marker/task cross-check, and the surviving-branch check
  each turn exactly one case red. The last of those was initially NOT covered -
  the "no landing commit" check fired first - so a half-landing scenario (a
  commit on master with the branch still present) was added to reach it.
- `test -x "$(nix build --no-link --print-out-paths
  .#homeConfigurations.alex.config.home.path)/bin/afk"` passes; the packaged
  binary also runs (`afk help`, and `afk run x` outside a repo exits 1).
- `bash home/modules/scripts/sprout-test.sh` 16/16,
  `bash home/modules/agents/skills/check.sh` clean, `tatr check` clean,
  `nix flake check` all checks passed.
- Still pending, as planned: the `manual:`-shaped real end-to-end run against a
  live Claude, blocked by the account's weekly rate limit. The fake-`claude`
  suite proves the control logic, NOT that `claude -p "/flow <id>"` resolves the
  skill or that a gate really surfaces as an ended turn once `AskUserQuestion`
  is denied. Those two assumptions are unverified until that run happens.

### Reflection

The runner is only as good as two contracts it does not own, and both are now
documented as such in `AGENTS.md`: Claude Code's stream-json shape and flag
names, and the flow skill's literal gate labels and statuses. The
`## Skills are a doc surface` section names `afk.sh`/`afk-test.sh` as machine
consumers so a future edit to `gates.md` cannot silently break the runner.

The stop policy is deliberately closed: unknown marker, foreign task ID, a gate
at the wrong step, an ineffective approval, a half-landing, a spike, a stall, a
rate limit and two no-progress sessions all exit non-zero with the task and its
worktree left exactly as they were, which is what makes `afk run <task-id>` a
safe retry. The cost is the one the DECISION already accepted: three human
checkpoints are gone, so a wrong plan now gets built further before anyone
looks.
