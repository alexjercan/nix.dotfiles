# Make the afk runner's output human readable

- PRIORITY: 60
- TAGS: agents, afk, ux
- KIND: TASK
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE

`afk run` currently prints a flat machine log (`CREATE CLAUDE SESSION <uuid>`,
`RUN /flow "<goal>"`, `AUTO_APPROVE WORK_DONE`). A watching human cannot tell
what phase the flow is in, what was just auto-approved and why, or whether a
long silent session is alive.

Requested:

- A live `WORKING...` spinner (`|/-\`) with the latest assistant message from
  the streaming session, trimmed to one line.
- Colors per state.
- The current flow phase shown clearly, not as a raw task title or path.
- Auto-approvals reported as what was approved and why it was automatic.
- A generally friendlier print format for the run's start, per-session
  progress and finish.

Constraints: no change to the control logic or the AFK marker protocol; the
output must stay sane when not a TTY (`afk-test.sh` parses it).

## Target output

Every permanent line is `<label>  <text>`, label padded, indented under its
session. Content is IDENTICAL on a TTY and off it; only ANSI color and the
transient spinner line are TTY-gated.

```
afk  unattended flow runner
repo  /home/alex/personal/nix.dotfiles
goal  add a thing

session 1  starting
  prompt  /flow "add a thing"
/ working  PLANNING  0m42s  writing the plan steps        <- transient, TTY only
  task    20260802-185402 created
  phase   PLANNING  writing the plan
  commit  a1b2c3d docs: plan the goal
  gate    plan ready - approved automatically, starting an afk run approves the flow gates
  phase   PLANNED  plan approved, ready to build

session 2  PLANNED
  prompt  /flow 20260802-185402
  ...
  next    rotating to a fresh context

session 3  COMPOUNDING
  ...
  gate    landing - approved automatically, starting an afk run approves the flow gates
  landed  9f8e7d6 feat: land thing
  cleanup feature/thing worktree removed

done  20260802-185402 landed
      3 sessions, 12m04s
```

## Steps

- [x] Add the presentation layer to `home/modules/scripts/afk.sh`: `OUT_TTY`
      / `ERR_TTY` from `[[ -t 1 ]]` / `[[ -t 2 ]]`, the color constants
      (empty when not a TTY), `line <color> <label> <text>`, and `say`/`err`
      clearing any live spinner first.
- [x] Add the phase gloss: one `case` mapping FLOW STEP to a short human
      phrase (UNDERSTANDING, PLANNING, PLANNED, WORKING, REVIEWING,
      COMPOUNDING, DONE). Unknown steps print bare.
- [x] Add the spinner to `run_claude`: poll the event pipe with
      `read -t 0.2` instead of `read -t $AFK_HEARTBEAT_SECS`, track the last
      event with `SECONDS` and die on the same heartbeat budget, and on each
      timeout redraw `<frame> working  <phase>  <elapsed>  <message>` with
      `\r\033[K`. Frames are `| / - \`. The message is the latest assistant
      text, whitespace-collapsed and truncated to the terminal width read
      once from `stty size` (fallback 80). No-op when not a TTY.
- [x] Reformat `cmd_run`, `gate`, `lifecycle_gate`, `report_commits` and the
      failure paths to the target output. `gate` names WHICH gate and WHY it
      was automatic. `die` prints `error  <msg>` then `afk run failed`;
      the interrupt path prints `interrupted`.
- [x] Update `home/modules/scripts/afk-test.sh`: rename `test_audit_log_order`
      to `test_run_report_reads_as_a_report` with the new ordered labels,
      fix the label substrings in `test_run_goal_full_cycle`,
      `test_run_task_id_resumes`, `test_failure_paths` and
      `test_interrupt_kills_recorded_pid`.
- [x] Add `test_spinner_and_color_only_on_a_tty` to `afk-test.sh`: a
      `reply_slow` fixture whose fake claude sleeps ~1s between the assistant
      event and the result, run once under `script -qec ... /dev/null` (a
      pty) and once captured normally. The pty run must show a spinner frame,
      the word `working`, the phase, and different colors for `gate` and
      `commit`; the plain run must contain no `\033` and no `working` line.
- [x] Run `bash home/modules/scripts/afk-test.sh` and
      `shellcheck -s bash home/modules/scripts/afk.sh`.

## Definition of Done

- The run prints a phase-by-phase report: repo/goal header, a numbered
  session block per session with its prompt and phase, commits, and a closing
  summary with the landed commit, session count and elapsed time.
  (test: `test_run_report_reads_as_a_report`)
- Every auto-approved gate names which gate it was and why it was automatic.
  (test: `test_run_report_reads_as_a_report`)
- On a TTY the run shows a live `working` spinner carrying the current phase,
  elapsed time and the trimmed latest assistant message, and colors the
  states differently; off a TTY the same run emits no escape sequence and no
  spinner line. (test: `test_spinner_and_color_only_on_a_tty`)
- The output reads better than the old machine log in a real terminal.
  (manual: user judgement)

## Notes

- The `AFK <STATUS> <id>` marker protocol, the `PROTOCOL` heredoc, the three
  `gates.md` approve labels and every routing/cross-check decision are OUT of
  scope. Only the printing changes. AGENTS.md's shared-vocabulary paragraph
  stays true, so no doc surface needs editing.
- Regression guard for the rewritten read loop: `test_failure_paths` already
  asserts `no output for 2s`, and `test_interrupt_kills_recorded_pid` already
  asserts the trap. Both must stay green; neither is a DoD item because both
  are green on the base branch.
- `AFK_VERBOSE=1` keeps printing full assistant text with the `| ` prefix.
  The spinner erases itself before any permanent line, so the two do not
  interleave; no mode flag is needed to combine them.
- Confirmed in scratch: `read -t 0.2` returns >128 per poll, `script -qec CMD
  /dev/null` allocates a pty and preserves the exit status (util-linux
  2.42.2, already in `afk.nix`'s `runtimeInputs`).
- No new runtime dependency: `stty` is coreutils, colors are literal ANSI.
- `script` is ambient for the hand-run test suite; `afk-test.sh` is not part
  of `nix flake check`, so this adds no sandbox requirement.

## Close-out

What/why: `afk.sh` gained a presentation section (TTY probes, color constants,
`spin`/`spin_clear`, `head_line`/`line`, `phase_gloss`) and every print site
was rewritten to the target report. `run_claude` now polls the pipe at 5 Hz
and enforces the heartbeat as an explicit `SECONDS` budget, which is what lets
the spinner advance while the model is silent. Control logic, the `AFK` marker
protocol and the three `gates.md` labels are untouched.

Alternatives: none beyond the two DECISION.md already rejected (dual
human/machine formats, a background animator process).

Difficulties and diagnosis:

- `read -t 0.2` saves partial input into the variable on timeout, so polling a
  pipe fast enough to animate will cut a long event line in half. Fixed by
  accumulating into `partial` across timeouts; confirmed directly in scratch
  that without it the first fragment is lost and with it the line reassembles.
- The new pty test failed by exactly one character. `stty size` under
  `script -qec` with a non-tty parent reports `0 0`, so `TERM_COLS` was 0 and
  `${text:0:-1}` silently became "all but the last character". The width guard
  now rejects anything under 20 columns and keeps the 80 fallback.

Evidence: `bash home/modules/scripts/afk-test.sh` 10/10 (was 9/9). Both DoD
tests were run against the base `afk.sh` and fail there for the intended
reason - no report labels, no gate rationale, no spinner, no color.
`nix flake check` (6 checks), `bash home/modules/agents/skills/check.sh`,
`bash home/modules/scripts/sprout-test.sh` (16/16), `tatr check` and
`shellcheck -s bash` on both scripts are green. `manual: user judgement` stays
pending. No doc surface quotes the old labels, so none needed editing.

Reflection: the plan's "poll instead of block" step was one line of intent
hiding two behavioural traps (partial reads, a lying `stty`). Both were only
visible because the suite drives the real script through a real pipe and a
real pty rather than testing the formatter in isolation.
