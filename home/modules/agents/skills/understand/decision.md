# Decision records

A `DECISION.md` records the choice this phase settled on, and why, so the
reasoning survives the chat and the next session does not re-litigate it. It
closes understanding, and planning reads it as authority: what TASK.md's Steps
build is whatever this record says.

Writing one is MANDATORY for any load-bearing build-shape fork - which
artifact, which mechanism, and the constraint that forced the choice. The
confirm and the record are one move: confirm the concrete artifact with the
user, then capture the confirmed choice, the rejected alternative, AND the
constraint that separated them, before anything is planned.

A choice made by inferring a shape, or confirmed in chat but never recorded,
is exactly the failure this record guards against. When a later phase finds
that the confirmed choice cannot satisfy every stated want at once, the task
rewinds here and the choice is re-confirmed; a quiet compromise is not an
option.

## Decision is not evidence

- A `SPIKE.md` holds the investigation the understand phase ran to reduce
  uncertainty about *what to build*. It is optional and only exists where
  there was something to explore.
- A `DECISION.md` records *a choice that was made*, whether or not any
  investigation preceded it. A dead-obvious choice with no alternatives worth
  weighing still gets a record if it is load-bearing; a choice reached through
  evidence cites that `SPIKE.md` rather than repeating it.

Do not manufacture an investigation to justify a decision you never actually
explored. Write the record directly.

## Where it lives

`tasks/<id>/DECISION.md`, in the folder of the task that owns the choice. A
choice that binds several tasks lives with the one they all depend on, and
each dependent's body carries a one-line pointer to it, so it is findable
without grepping every task folder.

Scaffold it - the generated record passes `tatr check` with its placeholders
in place:

```bash
tatr -r <task-root> scaffold <id> DECISION
```

## Supersede, do not rewrite

The `tasks/` tree is append-only history. A decision that later changes is NOT
edited in place. Write a NEW `DECISION.md` in the task that changes it with a
`- Supersedes: tasks/<id>/DECISION.md` header, and add the matching
`- STATUS: SUPERSEDED by tasks/<id>/DECISION.md` line to the old record. That
one-line lifecycle annotation is the only edit the old file takes. `tatr
check` flags a one-way link as `nonreciprocal-supersede` and an unresolvable
one as `dangling-supersede`.

## Format

`tatr scaffold` writes the headings and the metadata block; you fill them in.

- `## Context` - the forces that make this a real choice: constraints,
  requirements, what already exists. One paragraph. Cite a `SPIKE.md` here if
  one fed it.
- `## Decision` - the choice, in active voice, and why you would build it from
  scratch under today's constraints, not merely that it is what exists.
- `## Alternatives considered` - each rejected option, how it would have worked
  HERE, and why it lost. "Do nothing" is always a candidate; say what deferring
  costs.
- `## Consequences` - what gets easier AND what gets harder. The honest
  downsides are the part a cold reader cannot reconstruct.

`- STATUS:` is `ACCEPTED` or `SUPERSEDED by <ref>` and nothing else; any other
value is `bad-decision-status`. `- TASK:` must name an existing task, or it is
`dangling-decision-task`.
