---
name: plan
description: Turn understanding into implementation Steps and proof-bearing DoD. Use for /plan.
disable-model-invocation: true
---

# Plan

Turn completed understanding into an implementation plan. No understanding -> no plan.

## Input

* Requires `NOTES.md` from `/understand`.
* Read referenced PoCs, scripts, diagrams, experiments, and code.
* Do not use existing `TASK.md` content as planning context.
* Missing `NOTES.md` -> stop: "Missing NOTES.md. Run /understand first."

## Output

Write these sections to `TASK.md`:

```markdown
## Steps

- [ ] Implement <change>, following `<artifact/path>` where relevant.

## Definition of Done

- <observable result> (test: `<test name>`)
- <command succeeds> (cmd: `<command>`)
- <requires user judgement> (human: <check>)
```

## Rules

* Plan only from `NOTES.md`, its artifacts, and the codebase.
* Reference useful understanding artifacts directly from Steps.
* Ordered Steps. Name files, components, interfaces, or commands when known.
* No implementation.
* No speculative abstractions, modes, wrappers, or unrelated cleanup.
* Every DoD item requires one honest proof:

  * `test:` observable behavior with a meaningful failure case.
  * `cmd:` build, run, config, packaging, examples, or mechanical verification.
  * `human:` naming, UX, structure, taste, or other judgement.
* Do not invent tests to avoid `human:`.
* Replace existing `## Steps` and `## Definition of Done`. Preserve other `TASK.md` content without using it as input.
