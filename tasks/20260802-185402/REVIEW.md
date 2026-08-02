# Review: Make the afk runner's output human readable

- TASK: 20260802-185402
- BRANCH: feature/afk-human-output

## Round 1

- REVIEWER: out-of-context
- VERDICT: APPROVE

- [ ] R1.1 (MINOR) home/modules/scripts/afk.sh:516 - the session UUID is no
  longer printed anywhere, so after an unattended failure there is no direct
  `claude --resume <uuid>` handle for the session that failed; the old log
  printed it twice per session. Append it to the session header:
  `head_line "$C_SESSION" "session $session" "${step:-starting}  $SESSION_UUID"`.
  MINOR rather than MAJOR because the approved target output in TASK.md
  deliberately has no UUID and `claude --resume`'s picker still lists recent
  sessions.
- [ ] R1.2 (NIT) home/modules/scripts/afk.sh:144 - `spin` truncates with
  `${text:0:$((TERM_COLS - 1))}`, which counts characters, not display
  columns. An assistant message containing emoji or CJK wraps the transient
  line, and the `\r\033[K` in `spin_clear` then only clears the last physical
  row, leaving residue above it. Strip non-ASCII from `SPIN_MSG` by adding
  `tr -cd '[:print:]'` to the existing `tr` pipeline at line 363.
- [ ] R1.3 (NIT) home/modules/scripts/afk.sh:361 - the assistant `jq` text
  extraction now runs on every assistant event even when stdout is not a TTY
  and `AFK_VERBOSE` is unset, where `SPIN_MSG` is dead. Guard the extraction
  with `[[ $OUT_TTY -eq 1 || ${AFK_VERBOSE:-0} == 1 ]]` to keep the off-TTY
  path as cheap as it was.

Verification performed by this round:

- `bash home/modules/scripts/afk-test.sh` - 10/10 pass. master has 9
  `run_test` lines, the branch 10 (one renamed, one added), so the close-out's
  "10/10 (was 9/9)" is accurate.
- Both DoD tests re-derived independently against the base script: with
  `master:home/modules/scripts/afk.sh` swapped in, the branch suite reports
  5 passed / 5 failed, and `test_run_report_reads_as_a_report` and
  `test_spinner_and_color_only_on_a_tty` fail for the intended reasons - no
  report labels, no gate rationale, no spinner frame, no color. Tree restored
  clean afterwards.
- The load-bearing `read -t 0.2` partial-input claim re-derived from scratch
  against a real fifo: a writer emitting `HELLO-`, sleeping 0.5s, then
  emitting `WORLD\n` yields a timeout iteration holding `HELLO-` followed by
  the reassembled `HELLO-WORLD`. Without the `partial` accumulator the first
  fragment is lost, so the accumulator is required, not defensive.
- `nix flake check` - 6 checks, all passed. `shellcheck -s bash` clean on
  both scripts. `tatr check` clean.
- Heartbeat equivalence read line by line: `last_event` is refreshed on every
  complete read and on every partial arrival, and the budget is compared with
  `>=` against `AFK_HEARTBEAT_SECS`, so the rule is the old one with a
  finer-grained event definition. `test_failure_paths` (`no output for 2s`)
  and `test_interrupt_kills_recorded_pid` both stay green.
- Spinner containment audited: `SPIN_LIVE` is only set by `spin`, which
  returns early off a TTY; `say`, `err` and the end of `run_claude` all clear
  before any permanent write, so no permanent line can land on a spinner and
  no escape byte can reach a pipe.
- Documentation claim confirmed. `grep` for the old output vocabulary over the
  worktree hits only the unrelated `AFK RUNNER PROTOCOL` heredoc line and
  historical task records. `AGENTS.md:80-86` constrains the MARKER vocabulary
  and the three `gates.md` approve labels, all byte-identical on the branch,
  so it stays true unedited.

Pending user checks:

- `manual: user judgement` - "the output reads better than the old machine log
  in a real terminal". Not verifiable by a reviewer; run `afk run` once in a
  real terminal before landing.

Inspection commands:

```bash
cd "$(sprout show feature/afk-human-output)"
git diff master...HEAD
bash home/modules/scripts/afk-test.sh
nix flake check
```
