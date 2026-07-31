# Prototype mode

The question is about behavior: does this algorithm hold up on real input,
does this interaction read the way we imagine, does this integration actually
connect. Reading cannot settle it. Build the smallest thing that can.

A prototype here is exploratory, and exploratory code is kept. Deleting it
throws away the only evidence the recommendation rests on, and the next
session re-derives it.

## Where a prototype lives

Resolve the location in this order, and stop at the first that answers:

1. The repository's `AGENTS.md` `## Agent workflow` cache, if it names a
   location for prototypes and examples.
2. An established repo-native convention already in the tree - Rust
   `examples/`, a project `scripts/` or `demos/` directory. One that exists
   and is exercised by a check counts; one nobody has used does not.
3. `tasks/<id>/prototype/`, the default when neither of the above answers.

Ask the user only when more than one placement has meaningfully different
consequences - it would ship in the package, or be covered by a check someone
must now keep green. A choice with no consequence beyond tidiness is yours to
make. When you do ask, cache the answer in that `## Agent workflow` section in
the same change, so no later session asks again.

## Supported artifact

A prototype living in `examples/`, `scripts/` or `demos/` is part of the
repository's surface. It is landed like any other code: it builds, it has a
documented run command, and it is covered by whatever build or smoke check
guards that directory. Its README line says what it demonstrates.

If it cannot meet that bar, it does not belong there - move it to the task
folder rather than landing an example nobody can run.

## Retained evidence

A prototype under `tasks/<id>/prototype/` is evidence, not surface. Nothing
builds it and no check guards it, so the record has to stand on its own. In
the spike doc, alongside the artifact:

- its run command, verbatim and copy-pasteable, with any setup it needs;
- the observations it produced - what you saw, not what you concluded;
- the verdict it supports, and how far that verdict actually reaches;
- its limitations: the shortcuts, the faked inputs, the cases never exercised.

Record those while the prototype is in front of you. Written afterwards from
memory, the command drifts and the limitations quietly disappear - and a
reader who cannot re-run it after the spike closes has a story, not evidence.

The limitations list is the honest half. A prototype that faked the network,
ran one input, and skipped error paths supports a much narrower claim than its
demo suggests, and the next session needs that boundary more than the demo.

## Do not let it graduate by accident

Exploratory code proves a behavior is achievable. It is not the implementation
of that behavior: it has no tests, no error handling, and no review.

The accepted direction re-enters the normal lifecycle - a planned Story, work,
review - and the production version is written against production standards.
Reusing the prototype's code there is allowed; presenting it as already done
is not. When the Story lands, the prototype stays where it is as the evidence
for why the Story existed.
