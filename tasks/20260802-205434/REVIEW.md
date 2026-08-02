# Review: cover the afk SPIN_MSG CR/ESC sanitizer with a test

- TASK: 20260802-205434
- BRANCH: test/afk-spin-control-bytes

## Round 1

- REVIEWER: out-of-context
- VERDICT: APPROVE

No findings.

Verified independently, not read off the Notes:

- Unmutated suite: `passed: 15  failed: 0`, `test_spinner_strips_control_bytes`
  PASS.
- Mutation `tr '\n\t\033' '   '` at `home/modules/scripts/afk.sh:491` (CR
  leaks): `passed: 14  failed: 1`, with exactly the two recorded lines -
  "no frame is cut short by a carriage return" and "a frame carries the message
  past the stripped escape". Reverted, line re-read.
- Mutation `tr '\n\t\r' '   '` (ESC leaks): `passed: 14  failed: 1`, with
  "no frame body carries an escape byte". Reverted, line re-read.
- `tatr check` exits 0. Tree clean at review time.

Every DoD clause holds, and both mutation clauses were re-derived from scratch
rather than accepted from the record.

Design notes, not findings:

- The `bad_close` branch `continue`s before the `leaked`/`carried` checks, so a
  CR-split chunk cannot also be counted as an escape leak. Right ordering: the
  two mutations stay distinguishable by which assertions fire.
- The vacuity assertion (`carried`) is what stops a 40-column copy of the wrap
  test from passing trivially, and it doubles as the second CR signal.
- Considered and rejected: extracting the shared seed / `reply_slow` /
  `script -qec` block out of `test_spinner_never_wraps` and
  `test_spinner_strips_control_bytes` into one capture helper. It would delete
  about eight duplicated lines but couple two tests whose widths, payloads and
  frame-parse loops all differ; the helper's parameter list would be about as
  long as the duplication. Not worth a finding.
- `nix flake check` was not run: no Nix file changed, and `AGENTS.md` records
  that `afk-test.sh` is a hand-run check outside the flake. `afk.sh` itself is
  untouched, so no skill doc surface is invalidated.

Pending `manual:` items: none.
