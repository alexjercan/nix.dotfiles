# NOTES.md - the understanding record

Aim it at a human reading cold who has not seen the code. It is the one input
the ideators get, and the reason a later session does not re-litigate the
problem. `tatr` does not lint it; you own it.

```markdown
# Notes: <title>

## Problem Statement
## Context
## Ideas
```

Sections are written in that order, each only after its checkpoint clears.
Never draft ahead - an unconfirmed section is the guess the whole phase exists
to avoid.

## Problem Statement

The pain in the user's terms: what happens today, why it is a problem, and who
feels it. No solution vocabulary - no file names, no data structures.

Then `Not this:` - the neighboring problems this task is not solving. That
list is what stops the scope walking sideways during ideation, so name the
tempting adjacent ones, not absurd ones.

## Context

What the answer must respect, each with a one-line why:

- Surfaces: the files, modules or commands in play.
- Constraints: performance, compatibility, tooling, style, ownership. Every
  constraint the user stated, in their words, marked as theirs.
- Prior art: existing decisions, similar code already in the tree, and the
  dependency that might already do this.
- Unknowns: what nobody has answered yet, and whether it blocks.

An assumption recorded here is load-bearing. Mark it `Assumption:` so review
and retro can find what was guessed.

### Searching a codebase too big to read

Read it yourself when the problem names its files, or the tree is small enough
that one focused pass covers it. Otherwise send searchers - two to four, never
more, one per question you cannot answer:

- where does <behavior> actually happen today?
- what already exists that does something like <this>?
- who calls, configures or tests <surface>, and what breaks if it changes?
- what does <neighboring system> assume about <surface>?

Reaching this branch authorizes them, so a standing rule against delegating
unasked does not hold here.

Each gets one question, the repository path, and read-only tools. Each returns
at most 300 words: `file:line` anchors, what it found, and what it looked for
and did not find - that second half is the part that keeps the next search
from repeating it. No conclusions, no design, no writes.

You keep or drop every line yourself, because a searcher cannot tell what the
problem needs. Verify any anchor a constraint will rest on before recording
it; an unverified search result is a lead, not context.

## Ideas

One `### <n>. <title>` per surviving idea, ranked, best first. Each keeps its
pitch short - shape, cost, and why it placed where it did - and the losing
ones stay. A rejected idea with its reason is the record's most reusable part.

Merge two pitches only when they share a mechanism, and say so in the title.

## What it is not

Not a spec and not a plan. It carries no Steps, no Definition of Done and no
proofs; TASK.md owns those, and `DECISION.md` owns the ruling. Once planning
starts NOTES.md is frozen history: a section that goes stale stays stale, and
no later phase is bound by it.
