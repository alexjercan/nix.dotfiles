# Parallel planning lanes

Default: one planner. Open two or three lanes only for an expensive or
irreversible fork, independent domains, an Epic too large for one context, or
an explicit request for alternatives.

## Lenses

Each lane plans the whole task with a distinct optimization:

- Minimal end to end: smallest landable Story; explicit deferrals/costs.
- Deep interface: durable seams, names, and invariants.
- Migration/risk: callers, data, rollback, and irreversible edges.

Drop irrelevant lenses. No fourth lane without a genuinely missing angle.

## Packet

Give every lane the same read-only packet: task ID, verbatim request,
`tatr -r <task-root> context <id> --phase plan` artifacts, named
files/commands, its lens, and output cap. Exclude other replies and the
orchestrator's leanings.

Each returns at most 400 words: ordered Steps, DoD, and the likely blind spot
of other lenses. No narrative, code, writes, or worktree.

## Synthesize

The orchestrator:

1. Verifies claims, then selects or combines surviving parts.
2. Writes one TASK.md plan.
3. For a load-bearing choice, writes one DECISION.md with a short rejected
   alternative per losing lane and the ruling constraint.

Discard replies after synthesis; they are scratch, not task artifacts. If
lanes disagree on fact, check it before choosing. A lane needing write access
needs a spike instead.
