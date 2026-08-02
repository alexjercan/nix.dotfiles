# Decision: Drive flow with disposable headless Claude sessions from a shell runner

- DATE: 20260802-133711
- STATUS: ACCEPTED
- TASK: 20260802-132348
- TAGS: agents, flow, claude, shell

## Context

`/flow` already survives a cold start: every phase reconstructs state from
`tasks/<id>/`, `git`, and `sprout ls`, and the context cut is an explicit
instruction to `/clear` and re-invoke `/flow <id>`. The cost of a long run is
therefore not reasoning, it is the human sitting there re-typing that cycle and
answering three fixed approval gates whose labels are fixed strings in
`flow/gates.md`. `NOTES.md` records the design discussion behind this task; a
probe against Claude Code 2.1.220 established the concrete CLI and event
shapes cited below. The repository already has a precedent for this kind of
tool: `sprout.sh` plus a thin `writeShellApplication` wrapper plus a direct
integration test.

## Decision

Build `afk` as a plain bash script (`home/modules/scripts/afk.sh`) wrapped by
`afk.nix`, matching `sprout`. It supervises *disposable* Claude sessions:

- Ordinary continuation always starts a NEW session with a fresh `--session-id`
  UUID and the prompt `/flow <id>`. That is the `/clear` equivalent; there is
  no terminal automation and no transcript surgery.
- `--resume <uuid>` is used only to complete one approval transaction, sending
  the exact `gates.md` label for `PLAN_READY`, `WORK_DONE`, or `LAND_READY`.
- Authority stays with `tatr`, `git`, and `sprout`. A control marker injected
  through `--append-system-prompt` (`AFK <STATUS> <id>`) is a routing hint that
  must agree with `tatr show`; disagreement stops the run.
- `AskUserQuestion` is denied with `--disallowed-tools` so a gate cannot hang a
  headless turn; the gate surfaces as an ended turn plus its marker.
- Errors are detected from the terminal `result` event's `is_error` field and
  the process exit status, not from `subtype`: the probe returned
  `{"type":"result","subtype":"success","is_error":true,...}` for a rate limit.
- Stalls are caught by `read -t "$AFK_HEARTBEAT_SECS"` on the event stream, so
  a productive long turn is never killed by a wall-clock cap.

## Alternatives considered

- **Terminal automation (tmux send-keys of `/clear` and `/flow <id>`).** Would
  reuse the interactive path the user already knows, but it screen-scrapes an
  interactive UI, has no machine-readable result, and cannot distinguish a
  finished phase from a stalled one. Ending a headless invocation gives the
  same empty context with a structured terminal event. Rejected.
- **One long `--resume` chain for the whole flow.** Simplest control code, but
  it defeats the entire purpose: the context never gets cut, which is the
  problem being solved. Rejected.
- **Reuse or extend Scufris** (`/home/alex/personal/scufris`) as the engine.
  Its backend and supervisor shapes are genuinely proven and are copied here as
  patterns, but its database, session registry, event bus, HTTP surface, auth,
  MCP audience system and scheduler exist to serve a general multi-agent
  product. Flow records already are the durable state, and a serialized
  single-flow runner needs none of it. Rejected as an import, adopted as a
  reference.
- **A Python or Rust binary.** More natural parsing, but it breaks the
  `sprout` precedent, adds a build step to a script the user must be able to
  read and patch mid-run, and buys little: `jq` handles the stream. Rejected.
- **Do nothing.** The cycle stays manual. Cheap today; it keeps the operator
  pinned to a multi-hour loop whose every decision is already scripted.
  Rejected.

## Consequences

Easier: a long flow can run unattended, and the audit log is a single ordered,
greppable trace of sessions, gates, commits, and landing. The runner is one
readable shell file with a fake-`claude` integration test, so its control logic
is testable without spending model quota.

Harder: `afk` is now coupled to two contracts it does not own. Claude Code's
stream-json event shape and flag names can change under it, and the flow
skill's gate labels and statuses are matched as literal strings - editing
`flow/gates.md` or a skill's `## Output` contract silently breaks the runner,
so those files gain a hidden consumer. Auto-approval also removes the human
from three checkpoints that exist precisely to catch a bad plan early; the
mitigation is that every approval is verified against durable state and the run
stops closed, but a wrong plan will now get built further before anyone looks.
The rate limit means the first real end-to-end run is a manual check after this
task lands, not part of its automated proof.

## Implementation addendum (20260802, WORKING)

Three details settled during implementation, each load-bearing:

- **The audit log is derived, not scraped.** Every `FLOW`, `COMMIT`,
  `LAND COMMIT` and `TASK CREATED` line is read back from `tatr` and `git`
  after the session, never taken from Claude's prose. The same reason the
  marker is only a hint applies to the log: a scraped line records a claim, a
  derived line records what happened.
- **A gate is bounded on both ends.** afk refuses to answer a gate unless the
  task is in the FLOW STEP that gate is legal from (`PLANNING`, `WORKING`,
  `DONE`), and refuses to continue unless the approval produced the next step -
  or, for landing, both a new commit on the default branch and a deleted
  feature branch. A half-landing is a distinct, tested failure.
- **`sprout` is not a runtime dependency; `tatr` is.** The task/worktree
  association is read straight from `git config --worktree sprout.task`, so
  worktree discovery needs only git, while flow-state authority needs `tatr
  show`. `runtimeInputs` is therefore claude-code, tatr, git, jq, coreutils and
  util-linux.

Two shell facts the interrupt handling depends on, both reproduced in isolation
(detail in TASK.md's close-out): a background job in a non-interactive shell
inherits SIGINT ignored and cannot trap it, and bash defers a trap until the
current foreground command finishes - so the runner must block in an
interruptible builtin (`read -t`), which it does.
