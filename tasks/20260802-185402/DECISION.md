# Decision: Make the afk runner's output human readable

- DATE: 20260802-185715
- STATUS: ACCEPTED
- TASK: 20260802-185402
- TAGS: agents, afk, ux

## Context

`afk run` prints a flat machine log. Two consumers read it: a human watching a
long unattended run, and `afk-test.sh`, which captures the run through a
command substitution and asserts on substrings. A spinner and ANSI color
cannot go to a pipe, and the spinner also has to advance while the model is
silent, which the current blocking `read -t $AFK_HEARTBEAT_SECS` forbids.

## Decision

One content stream, TTY-gated decoration only. Permanent lines are
byte-identical on and off a TTY; exactly two things are gated on `[[ -t 1 ]]`,
the color constants (empty strings otherwise) and the transient spinner line
(a no-op otherwise).

`run_claude` polls the event pipe with `read -t 0.2` and enforces the
heartbeat as an explicit `SECONDS` budget since the last event - the same rule
the blocking timeout expressed, now separated from the read.

afk's PRINTED vocabulary is not its MARKER vocabulary. `AFK <STATUS> <id>`,
the `PROTOCOL` heredoc and the three `gates.md` approve labels are contracts
with the model and the flow skills and do not change here.

## Alternatives considered

- Two output modes, human and machine, selected by `[[ -t 1 ]]`: rejected.
  Two formats to keep in sync, and the machine format nobody reads would be
  the one under test.
- Keeping the blocking heartbeat read and animating from a background job:
  rejected. A second process to signal, reap and clean up on interrupt, to
  avoid one 5 Hz poll.

## Consequences

- The tests assert the exact text a human reads, so a format regression is a
  test failure.
- `afk-test.sh` needs a pty (`script -qec`) for the spinner case. It is a
  hand-run suite, not part of `nix flake check`, so this adds no sandbox
  requirement.
- The event loop wakes 5 times a second per session. The existing
  `no output for 2s` and interrupt-trap assertions guard the rewrite.
