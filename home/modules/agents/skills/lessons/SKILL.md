---
name: lessons
description: Compile a cycle's ephemeral scratch into the durable lessons ledger (LESSONS.md), then clear the scratch - so the ledger is the only thing that survives and nothing rots in a junk drawer. Use at the end of a /flow or development cycle, before a release, or whenever the user asks to compile/tidy the lessons with `/lessons`. Finds LESSONS.md wherever it lives (repo root or docs/). This is the release-time "compile-and-wipe" half of the ephemeral-docs model; /compound writes the per-task retro, /lessons folds the loose scratch in and wipes.
---

# Lessons - compile the scratch into the ledger, then wipe

The docs model this skill enforces: **`docs/` (or whatever the project uses for
working notes) is EPHEMERAL scratch.** During a cycle, write whatever notes,
investigations or design sketches you like - no structure required. Durable
knowledge has exactly two homes, and neither is a scratch drawer:

- **The lessons ledger** (`LESSONS.md`) - one-or-two-line distilled LESSONS with
  a slug, a sentence, an occurrence count and task ids. The insight a scratch
  note leaves behind goes here.
- **The reference docs** (a wiki / `docs/` reference pages, project-specific) -
  how the code and systems work, at full detail. Reference-grade substance from
  a scratch note is migrated there, not left as scratch.

`/lessons` is the ritual that makes that true: it reads the scratch, folds the
lasting insight into the ledger (and points reference-grade detail at the wiki),
then clears the scratch so only the durable record remains.

## When to run

- At the **Finish** of a `/flow` (folded in by the flow skill) - sweep up any
  loose scratch the per-task `/compound` retros did not capture.
- **Before a release/tag** - compile and wipe so the tag ships a clean scratch
  area (a project may gate this in CI; e.g. a `check-docs-clean` guard).
- Any time the user asks to **compile/tidy the lessons** or runs `/lessons`.

If the scratch is already clean and the ledger current, `/lessons` is a no-op
that says so.

## Workflow

1. **Locate the ledger.** Search, in order: `<repo-root>/LESSONS.md`, then
   `<repo-root>/docs/LESSONS.md` (a project may keep it either place - the ledger
   is moving out of `docs/` in some repos). Use whichever exists; if BOTH exist,
   prefer the root one and flag the duplicate to the user. If NONE exists, create
   `LESSONS.md` at the repo root (or `docs/` if that is where the project's other
   durable docs live) from the format below.

2. **Find the scratch.** The ephemeral scratch is the project's transient-notes
   area - typically everything under `docs/` EXCEPT the ledger itself and a
   permanent `README`, plus any dated investigation files the cycle left around.
   List it; if empty, stop (no-op).

3. **Distil each scratch item** into the ledger's terms - NOT a verbatim dump:
   - A lasting INSIGHT (a mistake paid for, a non-obvious gotcha, a decision and
     why) becomes one-or-two ledger lines (slug + sentence + task ids). If the
     slug already exists, BUMP its count and sharpen the one sentence (two lines
     is the cap); do not append a paragraph.
   - REFERENCE-grade substance (how a shipped feature works, at detail) is
     migrated to the project's wiki/reference doc instead, and only its lesson
     (if any) goes to the ledger.
   - Transient/superseded scratch (a resolved one-off, notes already captured in
     a task's RETRO/NOTES) carries no durable content - it just gets cleared.
   A scratch note usually yields at most one or two ledger lines; most of its
   bulk is transient. When unsure whether something is durable, it probably
   is not - the ledger stays terse.

4. **Append/bump in the ledger**, keeping it sorted into its sections (process
   vs domain lessons). A lesson reaching **three** occurrences moves to the
   ledger's "Pending promotions" section for the user to fold into a global
   guideline (AGENTS.md, a skill, or the tool itself) - flag it, do not
   self-promote. Detection is mechanical, not vigilance: after updating the
   ledger, run `tatr check --ledger <this file>` - it reports any `(x3)`+
   lesson still outside that section as `promotion-stalled`. For that to
   work, counts stay BARE until promotion - `(x3)`, never `(x3, note)`:
   the parenthesized annotation is the promotion marker
   (`(x3, PROMOTED <date> -> <target>)`), and an annotated count is
   invisible to the lint by design.

5. **Clear the scratch.** Run the project's wipe mechanism if it has one
   (e.g. `scripts/wipe-docs.sh`, which clears the scratch to the durable files
   idempotently); otherwise remove the distilled scratch files by hand. Leave
   ONLY the durable ledger (and a permanent model README if the project keeps
   one). Never delete the ledger or a reference doc.

6. **Report** what was folded in (the new/bumped slugs), what was migrated to the
   wiki, what was cleared, and any lesson that hit three occurrences and now
   awaits the user's promotion decision.

## Ledger format

```markdown
# Lessons ledger

One or two lines per lesson: slug, one sentence, an occurrence count, and a
task id or two. /compound and /lessons append new lessons or bump counts; two
lines is the cap. At three occurrences a lesson moves to Pending promotions.
Counts stay bare - (xN) - until the user promotes; a promoted lesson carries
the annotation (xN, PROMOTED <date> -> <target>), which also exempts it from
the promotion-stalled lint (tatr check --ledger).

## Process lessons

- `diagnostic-first` (x4): trace the exact reported scenario before theorizing
  a mechanism. 20260709-125640, 20260711-103527, ...

## Domain lessons (project-specific)

- `two-clocks` (family): FixedUpdate reads raw state, render-rate reads eased
  state; one computation, one clock, one frame. ...

## Pending promotions (3+ occurrences, user decides)

- `verify-first-plan-steps` -> plan skill: ...
```

## Guidelines

- Terse beats complete. A page of scratch usually leaves one sharp ledger line;
  the point of the ledger is that it is short enough to read before every task.
- Do not duplicate: an insight already captured by a task's `/compound` retro is
  already in the ledger - `/lessons` handles the LOOSE scratch, not a re-run of
  per-task retros.
- The ledger is the ONLY durable output of the scratch. If a note's substance is
  worth keeping and is not a lesson, it belongs in the wiki/reference - move it
  there before clearing, or the detail is lost.
- Wipe is not destructive of durable records: it clears SCRATCH only, never the
  ledger, the model README, or reference docs. When in doubt about a file's
  durability, distil/migrate first, ask if still unsure, then clear.

## Relationship to /compound and /flow

`/compound` writes ONE task's retro and appends that task's generalizable
lessons. `/lessons` is the cycle/release-level pass: it folds the loose,
non-task scratch into the ledger and clears the scratch drawer, so between
`/compound` (per task) and `/lessons` (per cycle) the ledger is the single
durable record and `docs/` never becomes a junk drawer. `/flow` runs `/lessons`
at its Finish step so a delivered goal always leaves a clean, current ledger.
