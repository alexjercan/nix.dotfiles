# Review: afk: rotate the session on a soft/hard context token limit

- TASK: 20260802-211703
- BRANCH: feature/afk-token-limit-rotation

## Round 1

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

- [x] R1.1 (MAJOR) home/modules/scripts/afk.sh:498 - the soft limit's "safe
  boundary" fires on the FIRST tool_result of a turn, not the last, so it does
  not hold when the turn issued parallel tool calls. Each tool_result arrives
  as its own `user` event (3639 single-result events, 0 multi-result events
  across 60 real transcripts), and 311 of 3301 tool-calling assistant turns
  (9.4%) issued more than one `tool_use`. An armed session that runs `Read` and
  `Edit` in parallel is SIGTERMed the moment `Read` returns, while `Edit` is
  still writing - the exact half-written edit the soft path exists to avoid.
  Track outstanding tools instead of assuming one: count `tool_use` blocks on
  each `assistant` event, decrement per `tool_result`, and fire the stop only
  when the count reaches zero. A count that never drains just leaves the soft
  limit unfired, which the design already calls best-effort. Correct the
  `user` arm's comment and DECISION.md's boundary claim with it.
  - Response: fixed in 857adb3. `run_claude` now carries `pending_tools`:
    each `assistant` event adds its `tool_use` count, each `user` event
    subtracts its `tool_result` count (clamped at zero), and the soft stop
    fires only when an armed session drains to zero. The `user` arm's comment,
    DECISION.md decision 2 and the Step's text all say count, not first
    result. New case: a two-`tool_use` turn whose second `tool_result` sits
    behind the fixture's 4s pause, asserting `elapsed -ge 3` - firing on the
    first result lands before it, which is how the case was falsified.
- [x] R1.2 (MAJOR) home/modules/scripts/afk.sh:738 - the `LAND_READY` arm's
  stopped-gate path is the one branch of this change with no test. It is not a
  call to `lifecycle_gate` but a hand-written copy of it (`feat_before`,
  `report_phase`, `report_commits`, `rotate_stopped`, `continue`), and its
  ticked Step names it explicitly ("a stopped landing gate rotates rather than
  dying on 'produced no commit'"). Add a case to `test_token_limit_rotation`
  that overrides the landing invocation (`gen_work_to_land 0` invocation 4)
  with an over-limit transcript and asserts the run rotates, reports, and does
  not die on the "produced no commit" check.
  - Response: fixed in 857adb3. The landing invocation 4 is now overridden with
    an over-limit transcript and an emptied side script, so the branch is
    genuinely unlanded when the gate is stopped; invocations 5 and 6 carry the
    fresh session's `LAND_READY` and the resume that lands. Asserts the run
    rotates, does not print "produced no commit", and still lands. Falsified
    against a `gate ... || true` variant of the arm: all four checks fail.
- [x] R1.3 (MINOR) home/modules/scripts/afk-test.sh:986 - `no session was
  stopped` is a nothing-happens assertion with no paired guard that the
  stimulus fired. Arming is implicit in `reply`'s default 57600 against
  `AFK_SOFT_TOKENS=1000`, so the case still passes if `soft_armed` is never set
  at all. Add `check "every session was over the soft limit" str_contains
  "$out" "tokens  57.6K"` so the case pins that these sessions really were
  armed and left alone, rather than never armed.
  - Response: fixed in 857adb3, exactly as written, placed before the
    `no session was stopped` line it guards.

Verified independently:

- `bash home/modules/scripts/afk-test.sh` - 14 passed, 0 failed.
- `nix flake check` - all checks passed.
- `bash home/modules/scripts/afk.sh help | grep -E 'AFK_(SOFT|HARD)_TOKENS'` -
  both documented.
- The `set -m` claim in DECISION.md decision 5, re-derived from scratch with a
  standalone probe: without monitor mode `kill -INT` on an async child is
  discarded (5014ms, rc=0); with it the child dies at once (310ms, rc=130).
  The fix is real and load-bearing, and without it the hard limit is inert.
- Doc-surface sweep for `AFK_SOFT_TOKENS`/`AFK_HARD_TOKENS`: `usage()` is the
  only surface documenting afk's knobs; no README, nix module or skill text
  mentions them.
- `report_commits` and `gate` both end on an `if` whose false branch returns 0,
  so neither can hand `lifecycle_gate` a spurious non-zero "stopped" result.
- The soft and hard cases assert `elapsed -lt 8` against a 10s fixture pause,
  so they pin WHEN the stop happens, not merely that it happened.

Not verified: that `user`/`tool_result` events reach `claude -p
--output-format stream-json` stdout in the same shape as the stored
transcripts. The close-out records a live check; the corpus measured above is
the stored `.jsonl`, which shares the event shape but is not the same stream.

## Round 2

- REVIEWER: out-of-context (fresh `/flow` session entering at REVIEWING)
- VERDICT: APPROVE

All three round 1 findings are fixed and each fix was falsified from scratch
against a mutated copy of `afk.sh` in a scratch tree, not taken on the
Response's word:

- R1.1 - `run_claude` carries `pending_tools`: `tool_use` blocks raise it on
  the `assistant` arm, `tool_result` blocks lower it (clamped at zero) on the
  `user` arm, and the soft stop fires only when an armed session drains to
  zero. Falsified by collapsing the `user` arm back to "fire on any
  tool_result": `the stop waits for the outstanding sibling tool` fails, so the
  new parallel-tool case really pins the count and not just the stop.
- R1.2 - the stopped landing gate now has a case. Falsified by replacing the
  arm's `if ! gate ... then report/rotate/continue` block with
  `gate ... || true`: all four of its checks fail, including the
  `produced no commit` guard. The arm remains a hand-written twin of
  `lifecycle_gate` (different pre-state: `feat_before`), which is a shape
  worth watching but not a defect in this diff.
- R1.3 - the `tokens  57.6K` guard is present and sits directly above the
  `no session was stopped` assertion it pairs with.

Re-run independently at HEAD (c088bc5):

- `bash home/modules/scripts/afk-test.sh` - 14 passed, 0 failed.
- `nix flake check` - exit 0, all checks passed.
- `bash home/modules/scripts/afk.sh help | grep -E 'AFK_(SOFT|HARD)_TOKENS'` -
  both knobs documented.

No new findings. No `manual:` proofs are outstanding.
