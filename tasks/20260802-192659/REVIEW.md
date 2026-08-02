# Review: afk: show the session's context token count, colored by budget

- TASK: 20260802-192659
- BRANCH: feature/afk-session-token-meter

## Round 1

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

- [x] R1.1 (MAJOR) home/modules/scripts/afk.sh:434 - the `tokens` line is
  printed only on the fully successful path, so every `die` inside
  `run_claude` throws the count away: the heartbeat kill (line 379), a
  nonzero claude exit (line 422), a stream with no terminal result event
  (line 426) and an `is_error` result (line 431). The Story's own premise is
  that a session "is about to compact or stall", and afk's stall detector is
  exactly the heartbeat kill - so the count is dropped in the one case it was
  requested for, and a session whose FIRST invocation dies reports no count at
  all. Extract the two guarded lines into `report_tokens()` (`spin_clear`,
  then the existing `[[ -z $SESSION_TOKENS ]] || line ...`) and call it before
  each of those four `die`s as well as on the success path; the heartbeat
  branch needs the `spin_clear` because it currently dies over a live
  spinner. Pin it with a fixture that emits an assistant event carrying usage
  and then exits nonzero, asserting `tokens  57.6K` is still reported.
  - Response: fixed. The print moved into `report_tokens()` (`afk.sh:157`),
    which `spin_clear`s, prints once and then clears `SESSION_TOKENS` so it
    cannot double-print. Two call sites cover all five exits: one before the
    heartbeat `die`, which is the only exit taken from inside the event loop,
    and one immediately after `wait` returns, which precedes the nonzero-exit,
    missing-result and `is_error` dies as well as the success path. Output
    order on the success path is unchanged - nothing printed between the old
    and new positions. `test_session_token_report` gained four cases, one per
    dying path (nonzero exit, heartbeat stall, error result, no terminal
    result); all four failed before the change.

Verified independently, not taken from the task record:

- `bash home/modules/scripts/afk-test.sh` - 11/11 green, including
  `test_session_token_report` and `test_spinner_and_color_only_on_a_tty`.
- `nix flake check` - all 6 checks pass, so shellcheck ran over the new
  `afk.sh` code.
- `shfmt -i 4 -ci -sr -d` on both scripts - no diff. `tatr check` - clean.
- The fixture's split across the four usage fields really does catch a
  dropped field: 57594+1+2+3, so any single omission formats as `57.5K` or
  `0.0K` and the `not str_contains "$out" "57.5K"` assertion bites.
- `fmt_tokens` truncates (`119999` -> `119.9K`), so no count is ever shown
  above a band it has not crossed; the band boundaries in `tok_color` match
  the DoD (120000 and 180000 land in the upper band).
- The usage-absent guard is real: `if .message.usage then ... else empty end`
  plus the `^[0-9]+$` test, so a stream with no usage yields no `0.0K` line.
- `[[ $used =~ ... ]] && SESSION_TOKENS=$used` is safe under the
  `writeShellApplication` wrapper's `errexit`: a failing left side of an
  `&&` list is exempt.
- Every ticked Step matches the diff, including the corrected header-comment
  step, whose deviation is recorded in the step itself rather than glossed.
- Doc sweep: `AGENTS.md` documents afk's MARKER vocabulary and its test
  suite, neither of which a new printed line invalidates. No stale mention.

- Process signal: the last plan step asked for "one real `afk run <id>`
  sanity read" and the implementer substituted a live
  `claude -p --output-format stream-json` probe, recording the substitution
  in the step. Honest and defensible - a nested `afk run` would spend real
  quota - but it means no end-to-end run of the feature outside the fake
  `claude` fixture happened. Worth a line in the retro about what the plan
  should have asked for instead.

## Round 2

- REVIEWER: out-of-context
- VERDICT: APPROVE

No findings. R1.1 is fixed and ticked; no regression came in with the fix.

Verified independently, not read from the Response:

- The fix is load-bearing, not decorative: deleting only the `report_tokens`
  call before the heartbeat `die` (afk.sh:391) turns
  `test_session_token_report` red on "a stalled session still reports the
  count". The tree was restored and re-confirmed clean afterwards.
- `report_tokens` (afk.sh:157) covers every exit from `run_claude`. Read
  against the source, the loop has exactly one `die` (the heartbeat kill),
  which now reports first; the remaining three dies - nonzero exit (441),
  missing terminal result (447) and `is_error` (451) - all sit after the
  `report_tokens` at line 432, which itself follows `rc=$?` so the exit
  status is captured before the print.
- No double print: `report_tokens` clears `SESSION_TOKENS` after printing,
  and `run_claude` re-empties it per invocation, so the heartbeat path
  cannot print twice and a second invocation cannot inherit the first's
  count. `test_run_report_reads_as_a_report` and the `-eq 4` count assertion
  in `test_session_token_report` pin one line per invocation.
- Success-path output order is unchanged: nothing is emitted between the old
  print site and the new one, and `test_run_report_reads_as_a_report`'s
  `in_order` sequence still passes with `tokens  57.6K` in place.
- Full suite run here: `bash home/modules/scripts/afk-test.sh` 11/11 green.
  `nix flake check` - all 6 checks pass, so shellcheck saw the new code.
  `shfmt -i 4 -ci -sr -d` - no diff on either script. `tatr check` - clean.
  Working tree clean.
- All seven DoD proofs are `test:`/`cmd:`; none is `manual:`, so there is no
  pending user check.

- Process signal: carried forward from round 1 - the last plan step asked for
  "one real `afk run <id>` sanity read" and got a live
  `claude -p --output-format stream-json` probe instead. The substitution is
  defensible (a nested `afk run` spends real quota) and was recorded in the
  step, but the plan should have asked for what it actually wanted: a probe
  confirming the `usage` shape. Worth a retro line.
