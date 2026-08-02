# Add an unattended afk flow runner

- STATUS: OPEN
- PRIORITY: 80
- TAGS: feature,agents,flow,claude
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

Add a small `afk` CLI, packaged like `sprout`, that runs this repository's
`/flow` skill through headless Claude Code. `afk run "<goal>"` and
`afk run <task-id>` automatically accept the standard flow gates, rotate to a
fresh Claude session at every requested context cut, and continue through
landing without routine user input.

## Steps

- [ ] Add the shell runner and Nix packaging, with only the `run` command and
      goal-or-task-ID input required for the first version.
- [ ] Drive `claude -p` as a serialized stream, print machine-readable audit
      events, resume a session only to answer a pending gate, and start a fresh
      session for normal `/flow <id>` continuation.
- [ ] Auto-approve `PLAN_READY`, `WORK_DONE`, and `LAND_READY`; verify each
      resulting lifecycle or Git state before continuing, and stop closed on
      errors, unknown questions, inconsistent state, stalls, or no progress.
- [ ] Add an integration-style shell test with a fake Claude executable that
      proves session creation, gate resumption, context rotation, landing, audit
      output, failure handling, and subprocess cleanup.
- [ ] Re-read the runner, package wiring, tests, and any affected flow docs;
      record the final design tradeoffs and verification in this task.

## Definition of Done

- `afk run "<goal>"` can drive a concrete goal from creation through landing,
  and `afk run <task-id>` can resume a planned or active flow from durable task
  and worktree state. (test: afk shell integration test)
- Every fresh Claude invocation prints `CREATE CLAUDE SESSION <id>` and the run
  prints flow statuses, automatic approvals, commits, checks, landing, and a
  final summary in execution order. (test: audit-log fixture assertions)
- Claude runs with `--dangerously-skip-permissions`; ordinary continuation gets
  a new session, while `--resume` is used only to answer the exact approval
  choice for a gate. (test: fake Claude argv log assertions)
- The runner exits nonzero without guessing when Claude errors, stalls, returns
  an unknown control result, fails a transition/landing verification, or makes
  no durable progress. (test: failure-path fixtures)
- The script preserves the Claude subprocess exit status, kills only its
  recorded PID on interruption, and leaves durable flow state resumable with a
  later `afk run <task-id>`. (test: interruption fixture)
- Repository checks pass. (cmd: bash home/modules/scripts/afk-test.sh && bash home/modules/scripts/sprout-test.sh && bash home/modules/agents/skills/check.sh && tatr check && nix flake check)

## Notes

- Design discussion and audit-output example: `NOTES.md`.
- Keep the runner flow-specific. Do not import Scufris's web, database, MCP,
  authentication, concurrency, or general agent-registry layers.
