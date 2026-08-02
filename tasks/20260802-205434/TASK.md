# cover the afk SPIN_MSG CR/ESC sanitizer with a test

- STATUS: OPEN
- PRIORITY: 30
- TAGS: agents, afk, test
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

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

## Definition of Done

- A raw CR and a raw ESC in assistant text do not reach a drawn spinner frame.
  (test: in `home/modules/scripts/afk-test.sh`)
- The whole afk suite is green.
  (cmd: `bash home/modules/scripts/afk-test.sh`)

## Notes

- Likely cheapest as an extension of `test_spinner_never_wraps`, which already
  builds a wide-character payload, drives a pty via `script`, and splits the
  raw capture into spinner chunks. A payload carrying `\r` and `\033[31m` plus
  an assertion that no frame chunk contains either, beyond the frame's own
  `\033[?7l`/`\033[?7h` and the leading `\033[K`, may be enough - note the
  frame legitimately contains ESC, so the assertion has to be about the
  MESSAGE part of the frame, not the whole chunk.
- Alternative if that proves fiddly: assert on `SPIN_MSG` at a unit seam. Only
  if the integration assertion cannot be stated cleanly - this repo prefers the
  integration boundary.
