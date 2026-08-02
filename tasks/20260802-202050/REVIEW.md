# Review: afk: name the Claude session ID on each session header line

- TASK: 20260802-202050
- BRANCH: feature/afk-session-id-header

## Round 1

- REVIEWER: out-of-context
- VERDICT: APPROVE

No findings.

Verified:

- Suite run here: `bash home/modules/scripts/afk-test.sh` - 12 passed,
  0 failed.
- Sabotage re-derived independently: reverting `afk.sh:569` to
  `"${step:-starting}"` turns only
  `test_session_header_names_the_claude_session_id` red, on all four of its
  asserts; the other 11 tests stay green. Tree restored clean afterwards.
- The new test asserts behavior, not execution: it extracts each fresh
  invocation's `--session-id` from `argv.log` and requires that exact UUID on
  the matching `session N` header, plus a negative assert that no header
  carries a flow step.
- `test_run_report_reads_as_a_report` was loosened only on the three
  `session N` needles; the ordering it pins is unchanged, and the dropped step
  text is now covered by the negative assert in the new test. Not a weakening
  to reach green.
- `head_line` (afk.sh:201) does not pad or truncate `$3`, so the UUID prints
  in full; `SESSION_UUID` is minted at afk.sh:564, before the header, and
  `step` is still live via `SPIN_PHASE`.
- Doc surface: `grep -rn 'session [0-9]\|session N' --include='*.md'
  --include='*.nix'` hits only `tasks/` (exempt). `afk.sh`'s presentation
  comment and `AGENTS.md`'s `## Check suite` entry describe neither the header
  format nor the step text, so both stay true.
- Close-out notes in TASK.md match the diff and the numbers reproduced here.

Pending user checks: none - both DoD proofs are `test:`.
