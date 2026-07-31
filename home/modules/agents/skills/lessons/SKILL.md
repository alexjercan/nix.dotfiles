---
name: lessons
description: Fold loose scratch notes into the durable lessons ledger, then clear the scratch. Use for `/lessons`, at a flow Finish, or before a release.
---

# Lessons - Distill and Clear Scratch

Durable homes: concise lessons ledger and full reference docs. Scratch is
ephemeral.

## Run

At flow Finish, before release/tag, or on request. A clean scratch/current
ledger is a no-op.

1. Locate the ledger and read its format.
2. Find transient notes using the repository's `## Agent workflow`. List them;
   stop if empty.
3. Distill each item:
   - lasting mistake, gotcha, or decision/why -> append or bump one ledger
     lesson;
   - shipped-system detail -> migrate to reference docs, retaining only its
     lesson;
   - transient/superseded material -> discard.
4. Keep sections sorted and run `tatr check --ledger <ledger>`.
5. List pending entries with `tatr ledger`. For each unanswered entry, ask
   the user for PROMOTE, DEFER, RETIRE, or ABSORBED, including count, sentence,
   and promotion cost. Record only their answer through `tatr ledger` with its
   required task/reason/target. PROMOTE creates a normal planned, reviewed
   task. Never answer or promote on the user's behalf.
6. Use the project wipe mechanism, else remove only distilled scratch. Keep
   ledger, permanent README, and reference docs. Ask if durability is unclear.

Do not duplicate lessons already captured by task retros. Existing slugs are
bumped and sharpened, never appended again. Terse beats complete.

## Output

New/bumped slugs, migrated docs, cleared/pruned files, dispositions and
PROMOTE task IDs; at most 100 words.

## Load on demand

- locating/formatting the ledger, or deciding promotion/retirement -> `ledger.md`
