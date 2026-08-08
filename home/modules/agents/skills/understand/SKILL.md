---
name: understand
description: Understand a problem through questions, grounded context, and investigation.
disable-model-invocation: true
---

# Understand

Understand the problem before solving it. No production implementation.

## Workspace

* Task ID -> `<task-dir>/NOTES.md`.
* No task ID -> `/tmp/understand-XXXXXX/NOTES.md`.
* Do not modify task state.

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
* Coding project -> inspect relevant code before proposing shapes.
* Prototype aggressively when it makes ideas concrete.
* Prefer interface prototypes for API/design work: types, signatures, ownership, data flow, and example usage.
* Prefer executable scripts/PoCs for uncertain behavior or assumptions.
* Keep prototypes minimal and disposable. They explore shape or evidence, not production implementation.
* Challenge prototypes. Look for awkward ownership, missing states, edge cases, and contradictions.
* Run prototypes when possible; record what they prove or disprove.
* Preserve useful artifacts beside `NOTES.md` and reference them from the notes.
* Update Context and Ideas as answers or experiments change understanding.
* Keep unresolved decisions in Questions.
* Investigate deeper when requested or when evidence is weak.
* User decides when understanding ends.
