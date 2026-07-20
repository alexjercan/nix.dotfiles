# Retro: Review skill: out-of-context reviewer is the round-1 default

- TASK: 20260720-152438
- BRANCH: feature/review-ooc-default (landed as 24aec4f via sprout land)
- REVIEW ROUNDS: 2 (R1 out-of-context: REQUEST_CHANGES, 1 MAJOR + 4 MINOR
  + 1 NIT; R2: APPROVE)

## What went well

- Self-referential catch: the out-of-context reviewer found a docs-only
  loophole in the very text defining out-of-context review - the carve-out
  wording would have exempted skill files, this repo's main substantive
  artifact, from the default. An in-session pass steeped in the intent
  would likely have read the intended meaning into the ambiguous sentence.
- The sprout land inside-the-worktree guard fired on its author two tasks
  after being written (land chained after an in-worktree commit); the
  refusal cost one retry instead of a half-landed state.
- The scripted-replace-asserts-match lesson from the previous retro paid
  out immediately: an assert caught close-out step text that had drifted
  from the plan wording.

## What went wrong

- The same close-out script that asserted correctly still let the commit
  run: the heredoc feeding python broke the && chain, so git commit
  executed on a new line regardless of the assert failing. The close-out
  landed one commit later than the skill edits. Root cause: commands
  placed after a heredoc block are not chained to it; the chain silently
  ended at EOF.
- The delivered carve-out initially dropped the substantive-branch escape
  hatch the plan specified, and the step was ticked anyway - caught by the
  reviewer as a spec-honesty finding (R1.2). Root cause: rewriting a step
  from memory of its intent instead of re-reading its exact text before
  ticking.

## What to improve next time

- Never put a commit after a heredoc in the same Bash call; gate it in a
  separate call on the previous call's success.
- Before ticking a Steps box, re-read the step's literal text against the
  delivered artifact (the same discipline the review skill now demands of
  DoD proofs).

## Action items

- [x] Ledger: bumped out-of-context-review-pass to x2; added
      heredoc-splits-the-chain and tick-against-the-literal-step.
