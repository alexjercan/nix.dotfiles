# Ideation lanes

Ideas are generated against the written problem, never against the
conversation. Invoking this phase IS the request for these lanes, so open them
even under a standing directive not to delegate unasked.

## How many

Count the surfaces and constraints in `## Context`:

- Three lanes: a new subsystem, a crossed module boundary, more than five
  surfaces, or no obvious shape.
- One lane, in this context, no subagent: a bug, a local change under three
  files, or a shape the tree already dictates.

Never a fourth lane. A second round of three replaces the first round, and it
only happens when the user rejected every idea.

## The brief

Each lane receives the task ID, the repository path, `tasks/<id>/NOTES.md`,
its mandate, the pitch format, and nothing else. Not the user's words, not the
chat, not your leaning, not another lane's reply - those carry the bias the
separate context exists to strip. A lane that needs more must ask for it as an
unknown rather than invent it.

Mandates, one per lane:

1. Cheapest: the smallest change that makes the problem stop. Deferrals are
   explicit.
2. Reuse: solve it with what already exists here, or with a dependency worth
   installing. Say plainly when nothing fits.
3. From scratch: what you would build today knowing the constraints, ignoring
   what exists.

Lanes may read the tree and search the web for prior art. They write nothing
into `tasks/` - their pitch goes to a scratchpad file and is scratch, not an
artifact.

## The pitch

At most 400 words, all of:

- The idea in two sentences, and why it is worth building.
- Data: the tables, models, types or records it defines or changes.
- Functions and interfaces it adds, with signatures.
- The files it touches, and where in each the change lands.
- A few illustrative diff lines per key change, marked illustrative. Never a
  patch.
- An ASCII shape diagram; mermaid only when ASCII cannot carry it.
- Assumptions, risks, and what would make this the wrong call.
- Cost, as a count and a size: files touched, new concepts, tests to write,
  new dependencies, and S, M or L overall.

Cost is the tiebreaker, so an unestimated pitch loses by default.

## Ranking

Read the pitches yourself before ranking, and verify any claim about the tree
that decides a place.

1. Fit: does it respect every constraint in `## Context`? A violation is
   elimination, not a demerit.
2. Convergence: a mechanism two lanes reached independently is stronger than
   one only the best writer proposed.
3. Cost: cheapest first among survivors.
4. Reversibility: prefer the one that is cheaper to undo.

Where two pitches share a mechanism and differ in reach, rank the shared
mechanism and record the reach as an option under it. Where all three fail on
fit, the context was wrong: go back and fix it before re-running the lanes.
