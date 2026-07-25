# Decision: durable flow state marker

- STATUS: ACCEPTED
- DATE: 20260725
- SCOPE: flow-family skills and tatr check

## Context

The current flow skills can treat task checklists as if they prove planning
happened, and `flow` always starts by creating a fresh umbrella task. That is
unsafe for `flow task <id>` resume cases: the named task might be stale,
wrong, incomplete, or manually populated with unchecked boxes by the user.

The user requirement is stricter: every flow must start from problem
understanding, ask or confirm before planning, and refuse implementation unless
the task file itself says the task was planned or the full planning artifacts
exist.

## Decision

Use a durable marker in the task's own `TASK.md`:

```text
## Flow State

- FLOW STEP: UNDERSTANDING|PLANNING|PLANNED|WORKING|REVIEWING|COMPOUNDING|DONE
- PLAN STATUS: APPROVED
```

`FLOW STEP` records the current phase. `PLAN STATUS: APPROVED` is written only
after the user explicitly accepts the plan. A `## Steps` checklist never counts
as proof that planning happened.

`tatr check` will enforce the mechanically checkable part: an `IN_PROGRESS`
task must have `PLAN STATUS: APPROVED` unless it is a history-exempt task type.
The skills will enforce the human part: start from understanding, compare the
user request against task contents, ask questions or state assumptions, and
stop at the plan gate until the user says to build.

## Alternatives Considered

- Treat `## Steps` as planned. Rejected because the user can write checkboxes
  before there is a confirmed plan.
- Store phase only in sidecar files. Rejected because the user asked for the
  task file itself to state the current step, and `tatr check` can parse
  `TASK.md` directly.
- Require approved markers on all old tasks. Rejected because it would dirty
  unrelated historical backlog. The hard required marker starts with
  `IN_PROGRESS` tasks, where accidental implementation is dangerous.

## Consequences

- Existing-task flow can reuse the named task folder without inventing an
  umbrella task.
- Fresh sessions can tell whether planning was approved from the task file
  alone.
- `/work` can fail fast before creating a worktree or changing task status.
- Old open backlog tasks remain valid until they are selected for work.
