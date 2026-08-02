# Decision: Keep AFK_VERBOSE, and cover it with a test

- DATE: 20260802-180242
- STATUS: ACCEPTED
- TASK: 20260802-143129
- TAGS: agents, flow

## Context

Round-1 NIT R1.4 on 20260802-132348: `AFK_VERBOSE` (`afk.sh:46`, `241-246`) is
an option with no test and no named caller, which the repo's concept budget
normally defers.

## Decision

Keep it, and add a test for both states. The invariant it serves: `run_claude`
consumes the whole stream-json stream and prints nothing from it. Without the
flag an unattended session is silent for its entire duration - minutes - and
the operator sees only `RUN`, then `FLOW`/status after it ends. `AFK_VERBOSE`
is the only in-tool way to watch a live run.

## Alternatives considered

- Delete it, and recover the text afterwards with `claude --resume` on the
  recorded session UUID. Rejected: post-hoc only. It does not help decide
  whether a running session is working or wedged, which is exactly when the
  heartbeat has not yet fired.
- Print assistant text unconditionally. Rejected: it drowns the audit lines
  (`RUN`/`FLOW`/`TASK CREATED`/status) that the runner's output exists for.

## Consequences

The knob stays, but stops being untested: `afk-test.sh` now asserts both that
`AFK_VERBOSE=1` echoes assistant text with the `| ` prefix and that the default
suppresses it. Changing the prefix or the event filter is now a test failure.
