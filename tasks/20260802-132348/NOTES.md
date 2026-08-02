# AFK flow runner design notes

## Intent

The main problem is the repetitive `/clear`, then `/flow <id>` cycle required
to keep long flow runs inside a small context window. Auto-approval supports
that goal; it is not the primary abstraction.

`afk` is a disposable-session supervisor for `/flow`:

```text
afk run "<goal>"
afk run <task-id>
```

Both forms mean: accept the normal flow defaults, proceed through every phase,
and land. Starting `afk run` is the user's upfront authorization for plan,
review, and landing gates. A manually planned task can first be moved to
`PLANNED`, then handed to `afk run <id>` for the common path.

## Execution model

- Always run Claude Code headlessly with `claude -p` and structured streaming
  output.
- Always pass `--dangerously-skip-permissions`. The target machine treats the
  checkout and its worktrees as rollback-able; no additional Claude permission
  policy is wanted.
- Keep `tatr`, Git, and `sprout` authoritative. Claude sessions are disposable
  execution contexts, not workflow state.
- Run from the main checkout. The flow skill discovers the task's sprout
  worktree and uses absolute paths.
- One serialized run. No database, web server, event bus, or concurrent run
  scheduler in the first version.

## Session algorithm

1. Mint a UUID and pass it with `--session-id` for every fresh Claude session.
2. Print `CREATE CLAUDE SESSION <id>` before starting it.
3. Invoke `/flow "<goal>"` initially, or `/flow <id>` for an existing task.
4. Capture the task ID and terminal control status from Claude's structured
   result. Cross-check it against `tatr show`, `sprout ls`, and Git state.
5. For `PLAN_READY`, `WORK_DONE`, or `LAND_READY`, resume that exact Claude
   session once and send the exact approval label required by `flow/gates.md`.
6. Verify that the approval caused the expected lifecycle or landing state.
7. Close the old context. Start a new session with `/flow <id>` for all ordinary
   continuation and checkpoint handoffs. Never use `--resume` for that path.
8. Exit 0 only after verified `GOAL DONE` and landing.

Literal `/clear` terminal automation is unnecessary and brittle. Ending a
headless invocation and starting a new session gives the intended empty context
while the new `/flow <id>` invocation reconstructs state from disk.

Resume is reserved for completing one approval transaction. If its transcript
has disappeared, start a fresh `/flow <id>` session, let flow reconstruct the
pending gate, then answer that newly emitted gate.

## Flow controls

| Result | AFK action |
|---|---|
| `PLAN_READY` | Resume, approve plan, verify `PLANNED`, rotate |
| `WORK_DONE` | Resume, approve review, verify `REVIEWING`, rotate |
| Context checkpoint | Verify committed checkpoint, rotate |
| `REQUEST_CHANGES` | Continue the normal review/fix loop |
| `LAND_READY` | Resume, approve landing, verify main and worktree state |
| `GOAL DONE` | Print summary and exit 0 |
| `SPIKED` or real decision question | Stop nonzero |
| Unknown or inconsistent result | Stop nonzero |

Pending `manual:` proofs remain pending and must never be reported as passed.
They do not create a new automatic answer; flow/tatr legality decides whether
the task can otherwise continue.

The driver should recognize only exact standard gate choices:

```text
Approve plan - move to PLANNED
Approve review - move to REVIEWING
Approve landing - land the branch
```

It must not answer arbitrary user questions with "yes".

## Machine result protocol

Inject a small protocol with `--append-system-prompt` so each Claude invocation
ends with one exact control record:

```text
AFK PLAN_READY <id>
AFK WORK_DONE <id>
AFK ROTATE <id>
AFK LAND_READY <id>
AFK BLOCKED <id> <reason>
AFK DONE <id>
```

The marker is a routing hint, not authority. An absent, malformed, or
state-inconsistent marker stops the runner.

## Audit output

The agreed shape is an ordered, human-readable log. Example:

```text
$ afk run "add automatic flow runner"

AFK RUN START
REPO /home/alex/personal/nix.dotfiles
GOAL add automatic flow runner

CREATE CLAUDE SESSION 3d72d159-ec57-46ca-a5d7-854694da8730
RUN /flow "add automatic flow runner"
TASK CREATED 20260802-143012
FLOW UNDERSTANDING
FLOW PLANNING
PLAN_READY 20260802-143012

RESUME CLAUDE SESSION 3d72d159-ec57-46ca-a5d7-854694da8730
AUTO_APPROVE PLAN_READY
FLOW PLANNED
CHECKPOINT COMMITTED 6a91d0e

CLOSE CLAUDE SESSION 3d72d159-ec57-46ca-a5d7-854694da8730
CREATE CLAUDE SESSION d06813f5-397c-4e17-aa93-e3c977ec6468
RUN /flow 20260802-143012
FLOW WORKING
WORKTREE feat/automatic-flow-runner
COMMIT 6c8ec84
CHECKS PASS
WORK_DONE 20260802-143012

RESUME CLAUDE SESSION d06813f5-397c-4e17-aa93-e3c977ec6468
AUTO_APPROVE WORK_DONE
FLOW REVIEWING

CLOSE CLAUDE SESSION d06813f5-397c-4e17-aa93-e3c977ec6468
CREATE CLAUDE SESSION cdcf389f-8e0e-4bb3-902d-57ce29a447f8
RUN /flow 20260802-143012
REVIEW ROUND 1
REVIEW APPROVE
FLOW COMPOUNDING
RETRO COMMITTED 164bf29
FLOW DONE
LAND_READY 20260802-143012

RESUME CLAUDE SESSION cdcf389f-8e0e-4bb3-902d-57ce29a447f8
AUTO_APPROVE LAND_READY
CHECKS PASS
LAND COMMIT c970c21
WORKTREE REMOVED feat/automatic-flow-runner

GOAL DONE 20260802-143012
CLAUDE SESSIONS 3
ELAPSED 38m12s
AFK RUN COMPLETE
```

The exact set of informational events can remain small. Session creation,
resumption, flow status, approval, landing, errors, and the final summary are
load-bearing.

## Failure and progress policy

Normal conditions that continue:

- Review findings and `REQUEST_CHANGES`.
- Test failures while the agent is actively diagnosing and fixing them.
- Multiple review/fix rounds within flow's existing limits.

Conditions that stop nonzero:

- Claude process or structured result error, including rate limits.
- No output beyond a generous heartbeat.
- Unknown control result or missing task ID.
- A gate approval that does not cause its required transition.
- Landing verification failure.
- Explicit flow stop condition or requirement decision.
- Multiple matching worktrees or otherwise inconsistent durable state.
- Two completed worker sessions with the same durable-state fingerprint.
- A bounded maximum number of session rotations.
- User interruption.

A useful no-progress fingerprint combines:

```text
FLOW STEP
main HEAD
feature HEAD
worktree dirty-state hash
latest review verdict
```

On interruption, kill only the recorded Claude PID, preserve its exit status,
and leave task/worktree state available to a later `afk run <id>`.

## Scufris comparison

The current `/home/alex/personal/scufris` master was inspected as the existing
general agent-engine reference. Only `v0.1.0` is tagged locally; "v0.3.0
engine" was treated as the intended architectural slice.

Reuse the proven shapes from `scufris/backends/claude.py`:

- `claude -p --output-format stream-json --verbose`.
- Fresh UUIDs through `--session-id`.
- Resume only when the session transcript exists.
- `auto` permission mode maps to Claude `bypassPermissions`.
- Parse terminal result/error events and ignore unknown additive event kinds.
- Kill and wait for the recorded subprocess on cancellation.

Reuse the policy from `scufris/supervisor.py`:

- No short wall-clock timeout for a productive run.
- A generous per-event heartbeat for genuine stalls.
- Terminal errors remain visible and machine-readable.
- Same-run serialization and bounded retained history/logs.

Do not copy Scufris's database, session registry, event bus/SSE relays, HTTP
surface, authentication, MCP audience system, concurrency scheduler, or web UI.
Flow records already provide the durable state `afk` needs.

## Likely repository shape

```text
home/modules/scripts/afk.sh
home/modules/scripts/afk.nix
home/modules/scripts/afk-test.sh
home/modules/scripts/default.nix
```

Package like `sprout`: keep the implementation in a directly testable shell
file and wrap it with `pkgs.writeShellApplication`. Likely runtime dependencies
are Claude Code, `jq`, Git, `tatr`, `sprout`, and UUID/locking utilities already
available from Nix packages.

Use a fake `claude` executable in the shell integration test. Record argv and
emit controlled stream-json sequences to prove fresh sessions, gate resumes,
rotations, audit ordering, transition failures, stalls, signals, and landing.

## Scope boundary

First version:

- One command: `run`.
- One flow at a time per repository.
- Goal string or task ID input.
- Full start-to-land behavior.
- Foreground process with streamed audit output.

Deferred unless evidence requires it:

- Background daemon or tmux ownership.
- `status`, `logs`, `stop`, or run-history commands.
- Multiple concurrent AFK flows.
- General backends beyond Claude Code.
- Web interface or Scufris integration.
