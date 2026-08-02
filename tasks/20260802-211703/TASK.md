# afk: rotate the session on a soft/hard context token limit

- PRIORITY: 70
- TAGS: agents, afk, feature
- KIND: TASK
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE

As an afk user I want a long-running session to be rotated on context size
instead of being allowed to run into the context window.

- Soft limit (~180K): stop the session at a safe boundary - let the tool call
  in flight finish - then rotate to a fresh session as if the session had
  reported ROTATE.
- Hard limit (~200K): stop immediately, CTRL+C style, then rotate.

A killed session emits no AFK marker, so the rotation must be driven by
durable state (tatr, git, sprout) the way /flow already reconstructs it.

## Steps

- [x] `home/modules/scripts/afk.sh`: add `AFK_SOFT_TOKENS` (default 180000)
      and `AFK_HARD_TOKENS` (default 200000) next to `AFK_HEARTBEAT_SECS` /
      `AFK_MAX_SESSIONS` at the bottom of the file, and document both in
      `usage()`'s Environment block.
- [x] `afk.sh` `tok_color()`: replace the literal `180000` hot-band threshold
      with `$AFK_SOFT_TOKENS`, so the red band means exactly "this session is
      being rotated". Keep the `120000` warn threshold literal.
- [x] `afk.sh` `run_claude()`: extract the kill-and-drain sequence the
      heartbeat path already open-codes (close `$sfd`, `kill`, `wait`,
      `CLAUDE_PID=""`, `rm -rf "$dir"`, `report_tokens`) into a
      `stop_claude()` helper taking the signal, so the heartbeat, soft and
      hard paths share one implementation and no path can leave the fd or the
      temp dir behind.
- [x] `afk.sh` `run_claude()`: on every `assistant` event that carries usage,
      after `SESSION_TOKENS` is updated, compare it against the two limits.
      `>= AFK_HARD_TOKENS` stops the session immediately with `SIGINT`
      (CTRL+C style). `>= AFK_SOFT_TOKENS` only ARMS the stop - it sets a
      local flag and prints nothing that a later stop would duplicate.
- [x] `afk.sh` `run_claude()`: handle the `user` event type in the event
      `case`. Count the `tool_use` blocks on each `assistant` event up and the
      `tool_result` blocks on each `user` event down; when the soft stop is
      armed and that count reaches zero, stop the session with `SIGTERM`. That
      is the safe boundary: a turn can issue tools in parallel, so only a zero
      count proves no half-written edit is being interrupted. An armed session
      whose turn simply ends first, or whose count never drains, is NOT
      stopped - its `result` event routes normally through its marker.
- [x] `afk.sh` `run_claude()`: set `KILL_REASON` (empty, or a human phrase
      naming the limit and the count) instead of `RESULT_TEXT` when a stop
      fires, and return before the `rc != 0` / missing-result / `is_error`
      checks - a session afk killed on purpose is not a session that failed.
      Reset `KILL_REASON=""` at the top of `run_claude`.
- [x] `afk.sh` `cmd_run()`: after the fresh `run_claude`, when `KILL_REASON`
      is non-empty, skip `parse_marker` entirely and take the same route the
      `ROTATE` marker takes - `report_phase`, `report_commits`, the
      `fingerprint` no-progress cross-check, and a `next` line naming the
      limit that fired. Durable state, not the missing marker, decides what
      the next session sees.
- [x] `afk.sh` `gate()` / `lifecycle_gate()`: propagate a stop during a gate
      resume as a non-zero return so `cmd_run` skips the post-gate
      `require_step` and rotates instead. A fresh `/flow <id>` re-reaches the
      same gate from durable state; a half-answered gate must not be treated
      as approved. The `LAND_READY` arm gets the same treatment, so a stopped
      landing gate rotates rather than dying on "produced no commit".
- [x] `home/modules/scripts/afk-test.sh`: add a `pause` fixture helper (write
      `$AFK_TEST_TMP/replies/$1.slow`) and refactor `reply_slow` onto it, so a
      `reply_raw` transcript can also hold the fake claude open before its
      last line. That is what makes a kill observable.
- [x] `afk-test.sh`: add `test_token_limit_rotation` covering, with
      `AFK_SOFT_TOKENS`/`AFK_HARD_TOKENS` set small: (a) soft limit plus a
      `user`/`tool_result` event rotates and a second session finishes the
      run; (b) the stop happens at the boundary, not after the transcript's
      pause; (c) an armed session with NO tool_result runs to its own result
      event and is routed by its marker; (d) the hard limit stops immediately
      with no tool_result event; (e) the rotated session's count is still
      reported by `report_tokens`; (f) two consecutive token rotations with no
      durable progress stop the run on the existing fingerprint check.
- [x] `afk-test.sh`: register the new case in the runner list at the bottom.
- [x] Update the presentation and driver comment blocks in `afk.sh` that
      describe the token meter and the heartbeat so they describe the limits
      too; the meter is no longer only a display.

## Definition of Done

- A session that crosses the soft limit and then completes a tool call is
  stopped at that boundary and the run continues in a fresh session.
  (test: `test_token_limit_rotation`)
- A session that crosses the soft limit but never completes another tool call
  is left alone and routed by its own marker.
  (test: `test_token_limit_rotation`)
- A session that crosses the hard limit is stopped immediately, without
  waiting for a boundary. (test: `test_token_limit_rotation`)
- A token-stopped session rotates through the same no-progress fingerprint
  cross-check as a `ROTATE` marker, so a stuck run still stops.
  (test: `test_token_limit_rotation`)
- Both limits are documented as environment knobs in `afk help`.
  (cmd: `bash home/modules/scripts/afk.sh help | grep -E 'AFK_(SOFT|HARD)_TOKENS'`)
- The whole afk suite stays green.
  (cmd: `bash home/modules/scripts/afk-test.sh`)
- The repo checks stay green.
  (cmd: `nix flake check`)

## Notes

- Evidence for the safe boundary: a stream-json transcript
  (`~/.claude/projects/*/*.jsonl`) carries `user` events whose content type is
  `tool_result`, one per completed `assistant`/`tool_use`. Confirm the same
  events appear on `claude -p --output-format stream-json` stdout during the
  work phase (the fixtures already fake them; the real stream is the claim
  under test) - if they do not, the boundary falls back to the `result` event
  and the soft limit degrades to "no early stop", which the plan must then
  record rather than silently ship.
- `run_claude` today treats every abnormal end as fatal (`die` on non-zero
  exit, on a missing `result` event, on `is_error`). The whole shape of this
  change is one new outcome - "afk stopped it on purpose" - threaded through
  those three checks and back into `cmd_run`'s routing.
- No new command, flag or marker status. `ROTATE` stays a model-reported
  status; the token stop reuses its ROUTE, not its marker.
- The heartbeat guard is unchanged and still independent: a silent session
  dies whether or not it is near a limit.
- Assumption: the 200K context window in `tok_color`'s comment is the real
  ceiling for these runs, so 180K/200K are the right defaults. They are
  environment knobs, so a different window is a setting, not a code change.

## Close-out

### What and why

`run_claude` grew a third outcome. A session now ends by reporting a marker, by
failing, or by afk stopping it on purpose because its context crossed a limit.
The third leaves `KILL_REASON` instead of `RESULT_TEXT` and returns before the
exit-status, missing-result and `is_error` checks, so `cmd_run` and both gate
helpers route it as a rotation rather than a death. The route it takes is the
`ROTATE` route unchanged - `report_phase`, `report_commits`, the no-progress
fingerprint, a fresh session - because durable state is what the next session
reads anyway. No marker is synthesized.

The soft limit only arms; the outstanding tool count reaching zero fires it.
The plan made that boundary conditional on the real stream actually carrying
those events, so it was verified first against a live
`claude -p --output-format stream-json` run: `assistant`/`tool_use` is followed
by `user`/`tool_result` on stdout, exactly as the fixtures fake it. No fallback
to the `result` event was needed.

### Alternatives

The kill-and-drain sequence was extracted into `stop_claude` rather than
duplicated across the heartbeat, soft and hard paths. It reads `$sfd` and `$dir`
from `run_claude`'s scope, which is a real coupling, but all three call sites
are inside that one function and the alternative - three copies of an fd close,
a kill, a wait, an `rm -rf` and a `report_tokens` - is exactly how a path ends
up leaking one of them.

The fingerprint check was factored into `require_progress` for the same reason:
a token rotation and a `ROTATE` marker must share one definition of "no durable
progress", or the token path would rotate forever.

### Difficulties

`test_token_limit_rotation` failed on one assertion: the hard stop took the
whole 10s pause instead of firing at once. The cause was not the test. A shell
without job control starts async commands with `SIGINT` set to ignore, and an
ignored disposition survives `exec`, so `kill -INT` on the claude child was
discarded - the hard limit did nothing at all and the session merely appeared
to stop when it finished. Confirmed with a standalone probe (`sleep 5 &` plus
`kill -INT`: 4s elapsed without `set -m`, 0s with it), then fixed by launching
the child under `set -m`. Recorded in DECISION.md as decision 5.

The test fixture had a matching problem: the fake claude's pause was a
foreground `sleep`, and bash defers a signal until the foreground child exits,
so every kill would have measured as taking the whole pause. The shim now waits
on a backgrounded sleep under a trap, which also makes the existing stall tests
finish promptly instead of sleeping out their fixtures.

### Round 2

Review round 1 found the soft boundary too narrow: a turn can issue several
tools at once and each result arrives as its own `user` event, so the first
result proved nothing while a sibling `Edit` was still writing. The boundary is
now a COUNT - `tool_use` blocks up, `tool_result` blocks down - firing only at
zero, with a count that never drains simply leaving the limit unfired. Two test
cases were added: a parallel-tool session whose second result is held behind
the fixture's pause (a stop on the first would land before it), and a landing
gate stopped mid-resume, which was the one branch of the change with no
coverage. Both were falsified against the pre-fix code before being kept.

### Evidence

- `bash home/modules/scripts/afk-test.sh` - 14 passed, 0 failed.
- `bash home/modules/scripts/afk.sh help | grep -E 'AFK_(SOFT|HARD)_TOKENS'` - both documented.
- `nix flake check` - all checks passed.
- `shellcheck -s bash home/modules/scripts/afk.sh` - clean, which is what
  `writeShellApplication` enforces at build time.

### Reflection

The plan's one conditional claim - that `tool_result` events reach stdout - was
worth checking before writing a line of it; had they not, the whole soft limit
would have degraded to nothing. The signal bug is the opposite lesson: the plan
named `SIGINT` and the code sent `SIGINT`, and it still did nothing. Only the
timing assertion caught it. A test that asserts a kill happened without
asserting WHEN would have shipped an inert hard limit.

Not covered: `AFK_SOFT_TOKENS`/`AFK_HARD_TOKENS` are unvalidated. A
non-numeric value makes the `-ge` comparisons error out per event. Every other
knob in the file is equally unguarded, so this stays consistent rather than
growing one special case.
