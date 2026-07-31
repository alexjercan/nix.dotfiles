# Decision records

A `DECISION.md` records a load-bearing choice that was made, and why, so the
reasoning survives the chat and the next session does not re-litigate it.

Writing one is MANDATORY for any load-bearing build-shape fork - which
artifact, which mechanism, and the constraint that forced the choice. The
confirm and the record are one move: confirm the concrete artifact with the
user, then capture the confirmed choice, the rejected alternative, AND the
constraint that separated them, before the build.

A choice made by inferring a shape, or confirmed in chat but never recorded,
is exactly the failure this record guards against. When you find mid-build
that the confirmed choice cannot satisfy every stated want at once, STOP and
re-confirm; do not quietly ship a compromise.

## Decision is not spike

- A `SPIKE.md` reduces uncertainty about *what to build* when the direction is
  fuzzy. It is optional and only fires when there is something to explore.
- A `DECISION.md` records *a choice that was made*, whether or not a spike
  happened. A dead-obvious choice with no alternatives worth weighing still
  gets a record if it is load-bearing; a choice reached by a spike cites that
  `SPIKE.md` as context rather than repeating it.

Do not force a spike to justify a decision you never actually explored. Write
the record directly.

## Where it lives

`tasks/<id>/DECISION.md`, in the folder of the task that owns the choice. For
a choice spanning an epic, the container's folder, plus a one-line pointer in
the container TASK.md `## Decisions` section so it is findable without
grepping every task folder.

Scaffold it - the generated record passes `tatr check` with its placeholders
in place:

```bash
tatr scaffold <id> DECISION
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
  requirements, what already exists. One paragraph. Cite a `SPIKE.md` here if a
  spike fed it.
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
