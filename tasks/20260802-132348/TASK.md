# Add an unattended afk flow runner

- STATUS: OPEN
- PRIORITY: 80
- TAGS: feature, agents, flow, claude
- KIND: TASK
- FLOW STEP: PLANNED
- PLAN STATUS: APPROVED

## Story

Add a small `afk` CLI, packaged like `sprout`, that runs this repository's
`/flow` skill through headless Claude Code. `afk run "<goal>"` and
`afk run <task-id>` automatically accept the standard flow gates, rotate to a
fresh Claude session at every requested context cut, and continue through
landing without routine user input.

## Steps

- [ ] Add `home/modules/scripts/afk-test.sh`: the sandbox harness modelled on
      `sprout-test.sh` (hermetic git, one mktemp repo per case, `check`/`not`/
      `str_contains` helpers) plus a fake `claude` shim placed first on `PATH`
      that appends its argv to `$TMP/argv.log` and replays a per-case
      stream-json fixture from `$TMP/replies/<n>.jsonl`.
- [ ] Add `home/modules/scripts/afk.sh` with `run`/`help` usage, main-worktree
      resolution copied from `sprout.sh`, goal-vs-task-ID input detection
      (`^[0-9]{8}-[0-9]{6}$`), and the `AFK RUN START` / `REPO` / `GOAL` or
      `TASK` audit header.
- [ ] Implement one Claude invocation in `afk.sh`: `uuidgen` session ID,
      `CREATE CLAUDE SESSION <uuid>`, `claude -p --output-format stream-json
      --verbose --dangerously-skip-permissions --disallowed-tools
      AskUserQuestion --session-id <uuid> --append-system-prompt <protocol>
      "/flow ..."`, consumed by a `read -t "$AFK_HEARTBEAT_SECS"` loop that
      prints audit lines and captures the terminal `result` event; a missing
      `result`, `is_error: true`, or a nonzero exit is fatal.
- [ ] Implement control routing in `afk.sh`: parse the trailing
      `AFK <STATUS> <id>` marker, cross-check `<id>` and FLOW STEP against
      `tatr show`, answer `PLAN_READY` / `WORK_DONE` / `LAND_READY` with a
      single `--resume <uuid>` turn carrying the exact `gates.md` label, verify
      the resulting FLOW STEP (or landed commit) before rotating, start a fresh
      session for `ROTATE`, print the summary for `DONE`, and exit nonzero for
      `BLOCKED`, unknown, or state-inconsistent markers.
- [ ] Implement the stop policy in `afk.sh`: a durable-state fingerprint (FLOW
      STEP, main HEAD, feature HEAD, worktree dirty hash, latest review
      verdict), stop on two identical consecutive worker fingerprints, bound
      rotations with `AFK_MAX_SESSIONS`, and trap INT/TERM to kill only the
      recorded Claude PID and exit with its status.
- [ ] Package it: `home/modules/scripts/afk.nix` wrapping `afk.sh` with
      `pkgs.writeShellApplication` (runtimeInputs git, jq, coreutils,
      util-linux, claude-code) and import it from
      `home/modules/scripts/default.nix`.
- [ ] Re-read the runner, packaging and tests; add `afk-test.sh` to the check
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
