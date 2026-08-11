---
name: understand
description: Explore a problem into implementation hints and a Definition of Done.
disable-model-invocation: true
---

# Understand

Understand the problem before solving it. No production implementation.

## Workspace

* Task ID -> `<task-dir>/NOTES.md`.
* No task ID -> create a directory with `mktemp -d`; write `NOTES.md` there.
* Do not modify task status.

## Notes

Maintain `NOTES.md` incrementally:

```markdown
# Notes: <title>

## Problem Statement
## Context
## Questions
## Ideas
```

## Rules

* Be highly interactive. Ask concrete questions in `## Questions`.
* Work in loops: inspect -> ask -> prototype -> verify -> update notes -> repeat.
* Explore wide before narrowing. Open Questions mean exploration is not done.
* Coding project -> inspect relevant code before proposing shapes.
* Prototype aggressively when it makes ideas concrete.
* Interface prototypes for API/design work: types, signatures, data flow, example usage.
* Executable scripts/PoCs for uncertain behavior or assumptions.
* Keep prototypes minimal and disposable. Run them; record what they prove or disprove.
* Preserve useful artifacts beside `NOTES.md`; reference them from the notes.
* Stay high level: data shapes, interfaces, affected files. No edit-level implementation detail.
* User decides when understanding ends.

## Close

When the user closes understanding, write to `TASK.md`:

* `## Steps`: implementation hints. Affected files, interfaces, shapes. Not an ordered recipe.
* `## Definition of Done`: observable outcomes.

Definition of Done items:

* Mark judgement items `(manual)`.
* Name a verifying command when one is obvious; do not invent one.
* Omit givens such as build and tests pass.

No `TASK.md` -> append the same sections to `NOTES.md`.
