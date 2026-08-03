# Decision: Gate understanding on a NOTES.md scratchpad the user approves

- DATE: 20260803-091640
- STATUS: ACCEPTED
- TASK: 20260803-091632
- TAGS: skills, flow, afk

## Context

`TASK.md` is a good plan and a poor briefing. Read cold it names Steps and
proofs but not what the feature will do, which files it lands in, or which data
structures and functions appear. The user asks for that briefing by hand today
("what files, what changes, what features"). Understanding is also the only
flow phase with no skill text and no stop: the router walks
`no ACTIVITY -> UNDERSTANDING -> PLANNING` in one motion, so nothing is
presented before planning begins.

## Decision

Understanding gets a conditional reference (`flow/understanding.md`), a durable
artifact (`tasks/<id>/NOTES.md`) and a real approval gate (`NOTES_READY`) that
blocks before PLANNING, using the same protocol as the three existing gates.

NOTES.md has a FIXED section list: What changes, Surfaces, Data and interfaces,
Sketches, Shape, Consequences and open questions. Diagrams are ASCII by
default - the user reads them in nvim - and mermaid only when ASCII cannot
carry the shape. Sketch diffs are indicative fragments, never full patches.

NOTES.md is a scratchpad, not a spec. `TASK.md` stays the plan's authority and
the only record `tatr` gates on; NOTES.md carries no proofs and is not
maintained once work starts.

`tatr` is not changed: leaving UNDERSTANDING earns no gate, so this is a
skills-level approval gate. `afk.sh` IS changed, because it routes on the
skills' status vocabulary and dies on an unknown status.

## Alternatives considered

- Inline confirmation with no new status: understanding asks its questions
  through the runtime's question tool and continues into planning in the same
  context. No afk change. Rejected by the user: under afk there is no user, so
  it silently degrades to no stop at all, and an approval that is not a gate is
  easy to skip.
- A loose menu of NOTES.md ingredients instead of fixed sections. Rejected:
  predictability when reading cold is the whole point.
- Teaching `tatr context --phase understand` to surface NOTES.md. Rejected for
  now: it is an external repo, and the skills can name the path directly.
- Raising the `flow/SKILL.md` body budget to fit the new route. Rejected: the
  budget is the forcing function that moved this material into a conditional
  reference in the first place. Trim prose instead.

## Consequences

- One more context cut per goal. Planning starts from a fresh context with
  NOTES.md and TASK.md on disk, which is cheaper than it sounds.
- `afk.sh` and `afk-test.sh` change with the skills, per the shared-vocabulary
  rule in `AGENTS.md`. Any label drift between `gates.md` and `afk.sh` breaks
  unattended runs.
- Two skill bodies (`flow/SKILL.md`, `plan/SKILL.md`) must be trimmed to
  absorb the new text; both sit within two words of their budget.
- Reviews gain a cold-read reference: `review/dimensions.md` already treats
  NOTES.md as a documentation surface.
