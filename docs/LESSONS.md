# Lessons ledger

One or two lines per lesson: slug, one sentence, an occurrence count, and a
task id or two. /compound and /lessons append new lessons or bump counts; two
lines is the cap. At three occurrences a lesson moves to Pending promotions.

## Process lessons

- `out-of-context-review-pass` (x1): a fresh-context round-1 reviewer
  sabotage-found an unfailable test the implementing session missed. 20260720-152433
- `commit-before-every-sabotage` (x1): the A/B commit-first rule applies per
  sabotage, not per task - a restore reverted uncommitted review fixes. 20260720-152433
- `scripted-replace-asserts-match` (x1): str.replace edits silently no-op on a
  one-char mismatch; assert the match and re-read the artifact. 20260720-152433
- `baseline-dod-proofs` (x1): run each DoD cmd: proof against the base branch
  at plan time - nix flake check was already broken on master. 20260720-152433

## Pending promotions (3+ occurrences, user decides)

(none yet)
