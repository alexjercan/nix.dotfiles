# Retro: review skill severity constraint

## What went well

- Applied last task's lesson immediately: the reviewer committed REVIEW.md on
  the branch as part of round 1, so it landed with the squash and the worktree
  was auto-removed cleanly (no stranded worktree, no reconstruction).
- Put the constraint in the two places that both reach the reviewer: Workflow
  step 4 (Write the findings) and the REVIEW.md Format severities bullet - the
  format section is exactly what the reviewer's prompt draws from per the skill's
  own line 37.
- The out-of-context reviewer verified the claims against the real tatr binary
  (found the literal `bad-severity ... (use BLOCKER|MAJOR|MINOR|NIT)` rule and
  confirmed only checkbox lines are parsed), so the skill text is accurate, not
  overclaimed. APPROVE, no findings.

## What went wrong

- Nothing material. One-round clean landing.

## What to improve next time

- Keep the pre-land REVIEW.md commit as the standard for the rest of this flow.

## Action items

- [x] Confirmed the rule/example agree (example uses only BLOCKER/MINOR).
- Fold `commit-the-review-before-landing` into LESSONS at Finish (proven twice now).
