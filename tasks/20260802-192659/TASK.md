# afk: show the session's context token count, colored by budget

- PRIORITY: 60
- TAGS: feature, scripts, afk
- KIND: TASK
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE

Watching an `afk run`, a human cannot tell how full the session's context is.
A session near the 200K window is about to compact or stall, and that is the
single number that predicts it. `afk` already consumes every stream-json
event, so the number is free.

Requested: show the current session's token count (e.g. `57.6K`), colored
green under 120K, yellow under 180K, red at 180K and above.

## Target output

One permanent `tokens` line per claude invocation, indented under its
session, plus the live count in the transient spinner:

```
session 2  PLANNED
  prompt  /flow 20260802-192659
/ working  WORKING  4m12s  57.6K  editing afk.sh      <- transient, TTY only
  tokens  57.6K
  phase   WORKING  building on the feature branch
  commit  a1b2c3d feat: thing
  gate    work done - approved automatically, ...
  tokens  61.2K
  phase   REVIEWING  reviewing the branch
```

`tokens` is colored on a TTY only, by the same rule as every other label:
green `< 120000`, yellow `< 180000`, red `>= 180000`. The spinner field is
uncolored - the spinner is truncated to the terminal width by byte count, and
an escape sequence cut in half would bleed color into the terminal.

## Steps

- [x] `home/modules/scripts/afk-test.sh`: extend the `reply` /`reply_slow`
      fixtures with a `usage` block on the assistant event (default 57600
      tokens) so every existing fixture exercises the new line, and add
      `test_session_token_report` covering the K format, the three color
      bands with their boundaries (119999 / 120000 / 180000), and a
      usage-free stream. Watch them fail.
- [x] `home/modules/scripts/afk.sh`: add `C_TOK_OK` / `C_TOK_WARN` /
      `C_TOK_HOT` to the color block, blanked off a TTY with the rest.
- [x] `home/modules/scripts/afk.sh`: add `fmt_tokens` (integer -> `57.6K`)
      and `tok_color` (integer -> the band's color constant).
- [x] `home/modules/scripts/afk.sh`: in `run_claude`, on each `assistant`
      event, sum `.message.usage` (`input_tokens` +
      `cache_creation_input_tokens` + `cache_read_input_tokens` +
      `output_tokens`) into `SESSION_TOKENS`, reset to empty at the top of
      the call, and append the formatted count to `SPIN_MSG`'s spinner line.
- [x] `home/modules/scripts/afk.sh`: after the terminal result, print the
      `tokens` line via `line`, skipping it when no usage was ever seen.
- [x] Update the `afk.sh` presentation header comment for the tokens line.
      Corrected against the DoD: the line is NOT a third TTY-gated thing -
      its value is content and prints off a TTY too, so the comment names
      what actually is gated (its band color) and why the spinner's copy of
      the count stays uncolored.
- [x] Run `bash home/modules/scripts/afk-test.sh` and a real sanity read.
      The suite is green; the real-stream read was a live
      `claude -p --output-format stream-json` probe re-confirming the usage
      shape (see the close-out) rather than a nested `afk run`.

## Close-out

What and why: `afk run` now prints one `tokens  <N.N>K` line per claude
invocation and carries the same count live in the spinner, so a human
watching an unattended run can see a session approaching its context window
instead of discovering it when the session compacts or stalls. The count is
the latest `assistant` event's `.message.usage` fields summed, colored green
below 120K, yellow below 180K, red at and above 180K.

Alternatives: none beyond the ones DECISION.md already settled (result-event
usage, cumulative tokens, high-water mark, a colored spinner). One plan step
was corrected rather than followed - see the step above.

Difficulties and diagnosis: the only trap was the usage-absent branch. The
obvious jq (`.message.usage | (.input_tokens // 0) + ...`) yields 0 rather
than nothing for a stream with no usage, which would have printed a false
`0.0K` line; the implementation guards with `if .message.usage then ... else
empty end` and only assigns when the result is numeric. `fmt_tokens`
truncates instead of rounding so a count can never be displayed above a
threshold it has not crossed.

Evidence: `bash home/modules/scripts/afk-test.sh` 11/11 green (was 3 red
before the implementation), `nix flake check` all checks passed (it builds
the writeShellApplication wrapper, so shellcheck ran over `afk.sh`),
`bash home/modules/scripts/sprout-test.sh` 16/16, `tatr check` clean, and
`shfmt -i 4 -ci -sr` reports no diff. A live
`claude -p --output-format stream-json --verbose` probe returned
`{"input_tokens":2,"cache_creation_input_tokens":4354,
"cache_read_input_tokens":18144,"output_tokens":4}` - the four fields the
parser reads, in the shape it expects.

Review round 1 (R1.1, MAJOR): the count was printed only on the fully
successful path, so all four `die`s inside `run_claude` threw it away -
including the heartbeat kill, which is afk's own stall detector and the
scenario the Story opens with. `report_tokens()` now owns the print and runs
on every exit. Four new cases in `test_session_token_report` pin one dying
path each.

Reflection: the cheap trick worth keeping is the band test harness. A
`DONE` marker on a task with no sprout worktree is a clean one-invocation
exit, so each color band costs a single fake session on a pty instead of a
four-invocation full cycle. Splitting the fixture's token total across all
four usage fields with distinct values also means a parser that drops one
field shows a wrong number rather than passing by luck.

## Definition of Done

- Each claude invocation reports its context size as a `tokens  <N.N>K` line
  under the session. (test: `test_session_token_report`)
- The count is the last assistant event's four usage fields summed, so it is
  the context size and not the turn's output. (test:
  `test_session_token_report`)
- On a TTY the label is green below 120000, yellow below 180000, and red at
  180000 and above, with 120000 and 180000 landing in the upper band. (test:
  `test_session_token_report`)
- A stream carrying no usage prints no `tokens` line and does not fail the
  run. (test: `test_session_token_report`)
- Off a TTY the `tokens` line is present and carries no escape sequence.
  (test: `test_spinner_and_color_only_on_a_tty`)
- The spinner carries the live count between the elapsed time and the
  message. (test: `test_spinner_and_color_only_on_a_tty`)
- The whole runner suite, including the fixtures now carrying `usage`, stays
  green; it is red from the moment `test_session_token_report` is written
  until the feature lands. (cmd: `bash home/modules/scripts/afk-test.sh`)

## Notes

- Confirmed by probing `claude -p --output-format stream-json --verbose`: the
  `assistant` event carries `.message.usage` with `input_tokens`,
  `cache_creation_input_tokens`, `cache_read_input_tokens` and
  `output_tokens`; their sum (22499 on a trivial prompt) is the context size.
  The `result` event carries the same fields under `.usage`.
- The fixture `reply` in `afk-test.sh` currently emits no `usage`, which is
  why the skip-when-absent branch is a real requirement and not speculation:
  a session killed before its first assistant event has no count.
- Thresholds are literals in `tok_color`. No env knob: nothing asks for one.
- `SESSION_TOKENS` is per claude invocation, and a gate resume is a second
  invocation on the same session, so its line legitimately reports a larger
  count.
- The count is the last event's, not a maximum: after a compaction the
  context genuinely shrinks and the display should follow it down.
