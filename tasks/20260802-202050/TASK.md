# afk: name the Claude session ID on each session header line

- STATUS: OPEN
- PRIORITY: 60
- TAGS: feature, scripts, afk
- KIND: TASK
- FLOW STEP: PLANNED
- PLAN STATUS: APPROVED

## Why

The afk runner prints one run-level header per Claude session:

    session 1  starting
    session 2  PLANNED

The flow step on that line is redundant: `report_phase` prints a `phase` line
with the same step plus a gloss as soon as the session finishes, and the
spinner carries it live. What the line does not carry is the one fact a human
cannot recover from disk - which Claude session produced this stretch of the
run. afk already mints that UUID (`SESSION_UUID=$(uuidgen)`) and passes it as
`--session-id`, so printing it makes every session directly openable with
`claude --resume <uuid>`:

    session 1  9f0f7a1c-0e2f-4a8e-9b3b-2c1d5e6f7a80

Scope: `home/modules/scripts/afk.sh` (one `head_line` call) plus its test
suite. Gate resumes reuse the session in flight and print no header, so they
are unaffected.

## Definition of Done

- Each `session N` header line names the exact Claude session ID that
  invocation was started with, so a human can `claude --resume` it.
  (test: `test_session_header_names_the_claude_session_id`)
- The session header no longer carries the flow step, and the report still
  reads in phase order.
  (test: `test_run_report_reads_as_a_report`)

## Steps

- [ ] `home/modules/scripts/afk-test.sh`: add
  `test_session_header_names_the_claude_session_id`, registered in the
  `run_test` list at the bottom. Drive `gen_goal_cycle` (three fresh sessions,
  invocations 1/3/5), then for each fresh invocation assert the printed
  `session N` header carries exactly the UUID that invocation's argv passed to
  `--session-id` (`argv_line`, same extraction as
  `test_argv_session_and_resume_policy`), and that no header line carries the
  old step text. Run it against unmodified `afk.sh` and confirm it fails.
- [ ] `home/modules/scripts/afk-test.sh`: make the `in_order` needles in
  `test_run_report_reads_as_a_report` step-free - `session 1  starting`,
  `session 2  PLANNED`, `session 3  REVIEWING` become `session 1`,
  `session 2`, `session 3`. The ordering they pin is the point; the step text
  is not.
- [ ] `home/modules/scripts/afk.sh`, `cmd_run`: change
  `head_line "$C_SESSION" "session $session" "${step:-starting}"` to print
  `$SESSION_UUID`. Keep `step`; `SPIN_PHASE=${step:-starting}` still uses it.
  Print the UUID in full, never truncated - a partial ID is not resumable.
- [ ] Re-read the presentation comment block at the top of `afk.sh` and the
  `## Check suite` entry in `AGENTS.md`; update only if either now states
  something false.
- [ ] Run `bash home/modules/scripts/afk-test.sh` and confirm the whole suite
  is green.

## Notes

- `SESSION_UUID` is minted at the top of the run loop, before the header is
  printed, so no reordering is needed.
- Sabotage check: reverting the `afk.sh` step alone turns
  `test_session_header_names_the_claude_session_id` red while the rest of the
  suite stays green. That test does not exist on the base branch, so it is red
  there by construction.
- The header is not a TTY-gated line, so the UUID lands in piped logs too.
  That is the point: the piped log is what a human reads after an unattended
  run.
- No doc surface outside `afk.sh` reproduces the report's session line -
  `grep -rn afk --include='*.md' --include='*.nix'` finds only `AGENTS.md` and
  the two nix wrappers, none of which quote the format.
