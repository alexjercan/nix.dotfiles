# afk: rotate the session on a soft/hard context token limit

- STATUS: OPEN
- PRIORITY: 70
- TAGS: agents, afk, feature
- KIND: TASK
- FLOW STEP: PLANNING
- PLAN STATUS: DRAFT

As an afk user I want a long-running session to be rotated on context size
instead of being allowed to run into the context window.

- Soft limit (~180K): stop the session at a safe boundary - let the tool call
  in flight finish - then rotate to a fresh session as if the session had
  reported ROTATE.
- Hard limit (~200K): stop immediately, CTRL+C style, then rotate.

A killed session emits no AFK marker, so the rotation must be driven by
durable state (tatr, git, sprout) the way /flow already reconstructs it.

## Steps

- [ ] `home/modules/scripts/afk.sh`: add `AFK_SOFT_TOKENS` (default 180000)
      and `AFK_HARD_TOKENS` (default 200000) next to `AFK_HEARTBEAT_SECS` /
      `AFK_MAX_SESSIONS` at the bottom of the file, and document both in
      `usage()`'s Environment block.
- [ ] `afk.sh` `tok_color()`: replace the literal `180000` hot-band threshold
      with `$AFK_SOFT_TOKENS`, so the red band means exactly "this session is
      being rotated". Keep the `120000` warn threshold literal.
- [ ] `afk.sh` `run_claude()`: extract the kill-and-drain sequence the
      heartbeat path already open-codes (close `$sfd`, `kill`, `wait`,
      `CLAUDE_PID=""`, `rm -rf "$dir"`, `report_tokens`) into a
      `stop_claude()` helper taking the signal, so the heartbeat, soft and
      hard paths share one implementation and no path can leave the fd or the
      temp dir behind.
- [ ] `afk.sh` `run_claude()`: on every `assistant` event that carries usage,
      after `SESSION_TOKENS` is updated, compare it against the two limits.
      `>= AFK_HARD_TOKENS` stops the session immediately with `SIGINT`
      (CTRL+C style). `>= AFK_SOFT_TOKENS` only ARMS the stop - it sets a
      local flag and prints nothing that a later stop would duplicate.
- [ ] `afk.sh` `run_claude()`: handle the `user` event type in the event
      `case`. When the soft stop is armed and the event carries a
      `tool_result`, stop the session with `SIGTERM`. That is the safe
      boundary: a tool result means the tool that was in flight has finished
      and no half-written edit is being interrupted. An armed session whose
      turn simply ends first is NOT stopped - its `result` event routes
      normally through its marker.
- [ ] `afk.sh` `run_claude()`: set `KILL_REASON` (empty, or a human phrase
      naming the limit and the count) instead of `RESULT_TEXT` when a stop
      fires, and return before the `rc != 0` / missing-result / `is_error`
      checks - a session afk killed on purpose is not a session that failed.
      Reset `KILL_REASON=""` at the top of `run_claude`.
- [ ] `afk.sh` `cmd_run()`: after the fresh `run_claude`, when `KILL_REASON`
      is non-empty, skip `parse_marker` entirely and take the same route the
      `ROTATE` marker takes - `report_phase`, `report_commits`, the
      `fingerprint` no-progress cross-check, and a `next` line naming the
      limit that fired. Durable state, not the missing marker, decides what
      the next session sees.
- [ ] `afk.sh` `gate()` / `lifecycle_gate()`: propagate a stop during a gate
      resume as a non-zero return so `cmd_run` skips the post-gate
      `require_step` and rotates instead. A fresh `/flow <id>` re-reaches the
      same gate from durable state; a half-answered gate must not be treated
      as approved. The `LAND_READY` arm gets the same treatment, so a stopped
      landing gate rotates rather than dying on "produced no commit".
- [ ] `home/modules/scripts/afk-test.sh`: add a `pause` fixture helper (write
      `$AFK_TEST_TMP/replies/$1.slow`) and refactor `reply_slow` onto it, so a
      `reply_raw` transcript can also hold the fake claude open before its
      last line. That is what makes a kill observable.
- [ ] `afk-test.sh`: add `test_token_limit_rotation` covering, with
      `AFK_SOFT_TOKENS`/`AFK_HARD_TOKENS` set small: (a) soft limit plus a
      `user`/`tool_result` event rotates and a second session finishes the
      run; (b) the stop happens at the boundary, not after the transcript's
      pause; (c) an armed session with NO tool_result runs to its own result
      event and is routed by its marker; (d) the hard limit stops immediately
      with no tool_result event; (e) the rotated session's count is still
      reported by `report_tokens`; (f) two consecutive token rotations with no
      durable progress stop the run on the existing fingerprint check.
- [ ] `afk-test.sh`: register the new case in the runner list at the bottom.
- [ ] Update the presentation and driver comment blocks in `afk.sh` that
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
