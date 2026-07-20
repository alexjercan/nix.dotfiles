# Retro: resolve 3 pending promotions

## What went well

- Treated "promote" as real folding, not just annotation: checked whether each
  lesson was already covered before deciding. dod-grep was already in the plan
  skill (task 220044), so it just needed the PROMOTED marker; edit-the-worktree
  and dry-run had genuine residue, so their guidance was folded into the work
  and plan skills respectively, then annotated.
- The reviewer independently opened both skills and confirmed the promoted
  guidance actually exists (not just claimed in the ledger) - the exact failure
  mode (a lesson marked promoted with no backing guidance) it was told to hunt.
- Ledger conformance is the objective gate: `tatr check --ledger` exits 0 and
  Pending promotions is empty.

## What went wrong

- Nothing material. One-round clean landing.

## What to improve next time

- Applying the just-shipped skill improvements to my own work paid off this
  whole flow: I drove every task with absolute worktree paths and git -C (the
  edit-the-worktree lesson) and never mis-committed from the wrong repo.

## Action items

- [x] All three lessons promoted with backing guidance; Pending promotions empty.
