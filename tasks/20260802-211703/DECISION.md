# Decision: afk: rotate the session on a soft/hard context token limit

- DATE: 20260802-211927
- STATUS: ACCEPTED
- TASK: 20260802-211703
- TAGS: afk, agents

## Context

afk already meters each session's context size (`SESSION_TOKENS`, the
`tokens` line) but only displays it. A worker session that keeps going past
the context window either compacts or errors out, and afk sees the failure,
not the cause. Rotating on size is cheap because every session is already
disposable: `/flow <id>` reconstructs its whole state from tatr, git and the
sprout worktree.

## Decision

1. Two thresholds, both environment knobs: `AFK_SOFT_TOKENS` (180000) arms a
   stop, `AFK_HARD_TOKENS` (200000) stops immediately with `SIGINT`.
2. The soft stop's safe boundary is the moment no tool is outstanding. A turn
   can issue several `tool_use` blocks at once and each result comes back as
   its own `user` event, so the runner counts tool calls up and results down
   and stops only when the count reaches zero - the only point at which a
   `SIGTERM` cannot interrupt a half-written edit. An armed session that
   reaches its own `result` event first, or whose count never drains, is not
   stopped at all.
3. A token stop synthesizes no marker. It reuses the `ROTATE` ROUTE -
   `report_phase`, `report_commits`, the fingerprint no-progress check, a
   fresh session - because durable state, not model prose, is what the next
   session reads anyway. `ROTATE` stays a model-reported status; the runner
   never fabricates one.
4. `tok_color`'s hot band becomes `$AFK_SOFT_TOKENS` rather than a second
   literal 180000, so red on the meter means "this session is being rotated".
5. The claude child is launched under `set -m`. A shell without job control
   starts async commands with `SIGINT` set to ignore, and an ignored
   disposition survives `exec`, so the hard limit's `SIGINT` was discarded
   silently - the session ran to its own end and only looked stopped. Monitor
   mode gives the child its own process group with default dispositions. It is
   then no longer in afk's group, so a terminal CTRL+C reaches it only through
   `on_signal`, which already kills the recorded PID by hand.

## Alternatives considered

- Stop immediately at the soft limit too. Rejected: it interrupts whatever
  tool is running, which is exactly the unsafe case the user asked to avoid,
  and the hard limit already covers the case where waiting is worse.
- Ask the model to wind down (inject a message) instead of killing. Rejected:
  headless `-p` has no side channel into a turn in flight, and a wind-down
  turn costs more context than the rotation saves.
- Add a `ROTATE`-on-tokens marker status to the protocol. Rejected: the model
  cannot see its own context size reliably, and the runner already can.
- Exempt gate resumes from the limits. Rejected: a gate resume inherits the
  whole session it is answering, so it is one of the largest invocations afk
  makes. A stopped gate rotates and the fresh session re-reaches the same
  gate from durable state.

## Consequences

- `run_claude` grows a third outcome ("afk stopped it") alongside success and
  fatal error, and `cmd_run`/`gate` must route it.
- A stopped gate resume can re-run a phase's gate question; the fingerprint
  check is what keeps that from looping forever.
- Every claude invocation now runs in its own process group. Nothing in afk
  signals a group, so the only behavioural change is the one above.
- The soft limit is best-effort by construction: a session that crosses it and
  then does nothing but talk runs to its own end. That is intended.
