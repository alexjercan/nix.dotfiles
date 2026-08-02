# cover the afk SPIN_MSG CR/ESC sanitizer with a test

- STATUS: OPEN
- PRIORITY: 30
- TAGS: agents, afk, test
- KIND: TASK
- FLOW STEP: PLANNED
- PLAN STATUS: APPROVED

## Why

Seeded by review finding R1.1 on 20260802-203817.

`home/modules/scripts/afk.sh` sanitizes `SPIN_MSG` with
`tr '\n\t\r\033' '    '`. The `\r` and `\033` were added by 20260802-203817
alongside the autowrap fix, on the reasoning that a transient decoration line
may not move the cursor or set a terminal mode, and model text quoting terminal
output carries both. That reasoning holds and the behavior was hand-verified,
but no test covers it: every Definition of Done clause on that task is about
wrapping, so dropping `\r` and `\033` back out of the `tr` set leaves the whole
suite green.

That is a behavior nobody can later justify from the checks. Someone
simplifying the sanitizer gets no signal.

## Steps

- [ ] Add `test_spinner_strips_control_bytes` to
  `home/modules/scripts/afk-test.sh`, next to `test_spinner_never_wraps`, and
  register it in the `run_test` list near line 1136.
- [ ] Build the payload without writing a literal control byte into the test
  source: `payload=$(printf 'alpha\rbeta\033[31mgamma')`, then
  `jq -Rs .` it to get the JSON string. Interpolate that into a `reply_raw 1`
  transcript with the same three events `test_spinner_never_wraps` uses.
  Keep `reply_slow 1 "AFK WORK_DONE $id" 1.2` before it so the pause survives
  the transcript replacement and at least one frame is drawn.
- [ ] Drive it through a pty exactly like the wrap test, but with
  `stty cols 80` instead of 40, so the ~27-char message clears the
  `${text:0:$((TERM_COLS - 1))}` truncation (the prefix
  `⠋ working  <step>  0m01s  57.5K  ` is ~34 chars).
- [ ] Split the raw capture on CR and keep the chunks opening with
  `\033[K\033[?7l` (frames), as the wrap test does. For each frame, strip the
  leading `\033[K\033[?7l` and the trailing `\033[?7h`, then assert the
  remainder holds no ESC. Assert every frame ends with `\033[?7h`.
- [ ] Assert at least one frame's remainder contains `[31mgamma`, so a frame
  that merely truncated the message away cannot pass the test vacuously.
- [ ] Verify red-on-base under BOTH mutations of the `tr` set at
  `home/modules/scripts/afk.sh:491` - `tr '\n\t\033'` (CR leaks) and
  `tr '\n\t\r'` (ESC leaks) - and record the two failure lines in Notes.
  Revert each mutation before moving on.
- [ ] Run the whole suite green.

## Definition of Done

- A raw CR and a raw ESC in assistant text do not reach a drawn spinner frame.
  (test: `test_spinner_strips_control_bytes` in
  `home/modules/scripts/afk-test.sh`)
- The new test is red if either `\r` or `\033` is dropped from the `tr` set at
  `home/modules/scripts/afk.sh:491`. (test: both mutation runs recorded under
  Notes)
- The whole afk suite is green.
  (cmd: `bash home/modules/scripts/afk-test.sh`)

## Notes

- Confirmed in scratch: a JSON `\r` and `\u001b` survive afk's
  `jq -r ... | join("\n")` extraction as raw bytes, and the current
  `tr '\n\t\r\033' '    ' | tr -s ' '` flattens both to a single space -
  `alpha beta [31mgamma`.
- Why CR is caught by an assertion about ESC-free remainders: a leaked CR
  splits the frame's own write, so the frame chunk loses its trailing
  `\033[?7h`. Hence the explicit "every frame ends with `\033[?7h`" assertion
  is the CR proof, and the ESC-free remainder is the ESC proof.
- Own test rather than an extension of `test_spinner_never_wraps`: that test
  needs a 40-col pty and a payload wide enough to be truncated, this one needs
  the message to SURVIVE truncation. Different widths, different invariants.
- Rejected: asserting on `SPIN_MSG` at a unit seam. The integration assertion
  states cleanly, and this repo prefers that boundary.
- The spinner frame carries no color of its own (`spin` uses `fmt_tokens`, not
  `tok_color`), so any ESC in the message part of a frame is a leak.
