---
name: lessons
description: Fold loose scratch notes into the durable lessons ledger, then clear the scratch. Use for `/lessons`, at a flow Finish, or before a release.
---

# Lessons - Compile the Scratch, Then Wipe

The model this skill enforces: the project's working-notes area is EPHEMERAL
scratch. During a cycle, write whatever notes you like there. Durable
knowledge has exactly two homes, and neither is a scratch drawer:

- **The lessons ledger** - one or two distilled lines per lesson.
- **The reference docs** - how the code and systems work, at full detail.

`/lessons` reads the scratch, folds the lasting insight into the ledger,
points reference-grade detail at the reference docs, then clears the scratch.

## When to run

- At a `flow` Finish, to sweep up scratch the per-task retros did not capture.
- Before a release or tag, so the tag ships a clean scratch area. This is the
  release-level pass that also prunes RETIRED entries.
- Whenever the user asks to compile or tidy the lessons.

A clean scratch and a current ledger make this a no-op that says so.

## Workflow

1. **Locate the ledger** and read its format before touching it.

2. **Find the scratch.** The project's transient-notes area - typically
   everything under its working-notes directory except the ledger and a
   permanent README, plus any dated investigation files the cycle left around.
   The repository's AGENTS.md `## Agent workflow` cache names it. List it; if
   empty, stop.

3. **Distil each item**, never dump it verbatim:
   - A lasting INSIGHT - a mistake paid for, a non-obvious gotcha, a decision
     and its why - becomes one or two ledger lines. An existing slug is
     BUMPED and its sentence sharpened, not appended to.
   - REFERENCE-grade substance - how a shipped feature works, in detail -
     migrates to the reference docs, and only its lesson goes to the ledger.
   - Transient or superseded scratch carries no durable content and is just
     cleared.

   A page of scratch usually yields one sharp line. When unsure whether
   something is durable, it probably is not.

4. **Append or bump**, keeping the ledger's sections sorted. Then run
   `tatr check --ledger <ledger>`: it reports any `(x3)`-or-more lesson still
   outside `## Pending promotions` as `promotion-stalled`.

5. **Settle every pending promotion.** `tatr ledger` lists each entry and
   whether it still awaits an answer. For every one that does, put the choice
   to the user - PROMOTE, DEFER, RETIRE or ABSORBED - using the platform's own
   user-input mechanism where it has one, and plain prose where it does not.
   Give the lesson's sentence, its count, and what promoting it would cost.

   Record the answer with `tatr ledger -s <slug> -D <disposition>` and its
   payload; the tool owns the annotation. A DEFER, RETIRE or ABSORBED is then
   cached in the ledger and is not raised again until the count moves past the
   one the DEFER was taken at.

   A PROMOTE becomes a normal planned tatr task, named by `-t <task-id>`, and
   the change it authorizes takes the usual out-of-context review before it
   lands. Never self-promote a lesson into a tool, template, AGENTS.md or
   skill, and never answer on the user's behalf when they are reachable.

6. **Clear the scratch.** Run the project's wipe mechanism if it has one,
   otherwise remove the distilled files by hand. Leave ONLY the durable ledger
   and any permanent README. Never delete the ledger or a reference doc; when
   in doubt about a file's durability, distil or migrate it first, ask if
   still unsure, then clear.

## Guidelines

- Terse beats complete. The point of the ledger is that it is short enough to
  read before every task.
- Do not duplicate: an insight a task's `compound` retro already captured is
  already in the ledger. `/lessons` handles the LOOSE scratch, not a re-run of
  per-task retros.
- If a note's substance is worth keeping and is not a lesson, it belongs in
  the reference docs. Move it there before clearing, or the detail is lost.
- Wipe is not destructive of durable records. It clears scratch only.

## Output

New and bumped slugs, what migrated to the reference docs, what was cleared,
any pruned RETIRED entries, and the disposition recorded for each pending
promotion with the task any PROMOTE now points at - 100 words or fewer.

## Load on demand

- locating the ledger, its format, or a promotion or retirement decision -> `ledger.md`
