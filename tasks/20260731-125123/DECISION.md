# Decision: Write the sabotage-at-plan-time rule into the proofs reference

- DATE: 20260731-130220
- STATUS: ACCEPTED
- TASK: 20260731-125123
- TAGS: skills, docs

## Context

The `write-the-sabotage-first` lesson recurred three times and was promoted to
this task. Its payload is a rule (delete or invert the clause a proof pins,
confirm it goes red ALONE), two failure modes invisible to running the proof,
and a timing constraint (plan, not work). `plan/proofs.md` is 790 of its 1000
word `reference-budget`, so ~210 words are available and the placement had to
be chosen before wording.

## Decision

The rule gets its OWN section, placed after `## Proofs must be able to fail`.
User selected 2026-07-31.

## Alternatives considered

- A clause inside `## Proofs must be able to fail`. Cheapest in words and keeps
  one heading for one idea. Rejected: that section is design-time reasoning
  ("ask what would make it red") expressed as three shape-specific bullets, so
  a procedure with two failure modes and a timing constraint would read as a
  fourth proof shape rather than a gate, and the plan-time timing - the part
  three recurrences missed - is the easiest line to skim past in a bullet list.

## Consequences

- Costs ~15 words of heading and framing overhead against the 210-word margin;
  the wording still has to stay tight to keep `reference-budget` green.
- The two sections are now adjacent peers: one says a proof must be ABLE to
  fail, the next says prove it by making it fail. The second is the gate for
  the first.
