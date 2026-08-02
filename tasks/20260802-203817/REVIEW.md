# Review: afk spinner must never wrap to a second row

- TASK: 20260802-203817
- BRANCH: fix/afk-spinner-wrap

## Round 1

- REVIEWER: out-of-context. The implementation landed in an earlier session;
  this session opened the task fresh and read the diff for the first time here.
- VERDICT: APPROVE

- [ ] R1.1 (MINOR) `home/modules/scripts/afk.sh:431` - the `SPIN_MSG`
  sanitizer's new `\r`/`\033` flattening is the one behavior change in the diff
  with no proof behind it. Every DoD clause is about the wrap, so nothing goes
  red if the two extra characters are dropped from the `tr` set. Verified by
  hand instead (`printf 'a\033[31mb\rc\td\n' | tr '\n\t\r\033' '    '` flattens
  all four), so it is correct as written - the gap is coverage, not behavior.
  Actionable: either extend `test_spinner_never_wraps` with a payload carrying
  a raw CR and ESC and assert the drawn frame carries neither, or seed a
  follow-up task. Not blocking: the change strictly narrows what reaches a
  decoration line.

### Verification

Independently re-derived rather than accepted from the records:

- Sabotage of `spin()` (dropping `\033[?7l`/`\033[?7h` from the frame write):
  `test_spinner_never_wraps` FAILs, whole rest of the suite stays green
  (12 passed / 1 failed). The test is load-bearing for the primary DoD clause.
- Sabotage of `spin_clear()` (dropping the trailing `\033[?7h`): FAILs on the
  distinct assertion "erasing the spinner also restores autowrap", so the
  second DoD clause has its own independent guard rather than riding on the
  first.
- `tr` octal escape confirmed empirically: `\033` in the set is the ESC
  character, not a literal backslash-zero-three-three.
- `reply_slow` writes `<n>.slow` and `reply_raw` writes `<n>.jsonl`, so the
  test's comment is accurate - the raw transcript replaces the reply while the
  pause survives, which is what makes a frame get drawn.
- Full suite green at HEAD: 13 passed, 0 failed. `tatr check` clean.
- `AGENTS.md`'s `## Check suite` entry for `afk-test.sh` states nothing the
  diff falsifies; correctly left alone.

### Judgement on the approach

The counterfactual holds: building this from scratch today still gives
autowrap-off over width measurement. It deletes the whole concept of "compute
the display width of arbitrary model text in bash" - no `wcswidth` shell-out
per frame, no East Asian Width table, no `SIGWINCH` trap - and it is
cause-agnostic across all three variants named in the Why (character-vs-column
counting, the startup-sampled `TERM_COLS`, and the 80-column fallback). Leaving
the existing truncation in place as a bound on the write, explicitly documented
as no longer the wrap guard, is the right call: it keeps the frame readable
without pretending to be correctness.

Comments match the repository's density and explain the non-obvious parts (why
one `printf`, why the permanent lines are deliberately not wrapped). The
presentation comment block's false claim about byte-count truncation is
corrected rather than deleted.

### Pending manual checks

None. No `manual:` proofs in the Definition of Done.
