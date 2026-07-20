# Retro: plan skill DoD-grep excludes tasks/

## What went well

- Small, surgical doc-surface change landed clean in one review round (APPROVE,
  no findings). The `(cmd: ...)` bullet was the right home per
  `document-where-the-reader-reads` - the guidance sits where a proof-author reads it.
- Kept it generic (placeholder symbol, `src/ docs/` and `--exclude-dir=tasks`
  examples, no repo-local paths), honoring the skills-are-a-doc-surface rule.
- The out-of-context reviewer independently reproduced `--exclude-dir=tasks` in a
  scratch dir rather than trusting the prose - exactly the value the round-1
  reviewer is meant to add.

## What went wrong

- The reviewer wrote REVIEW.md inside the worktree but never committed it to the
  branch, so `sprout land` (which squash-lands only tracked, committed files and
  then removes the worktree) discarded it. REVIEW.md had to be reconstructed in
  the main checkout from the reviewer's returned summary. The earlier "contains
  modified or untracked files" message was about that same untracked REVIEW.md.

## What to improve next time

- Commit the review artifact on the feature branch BEFORE landing, so REVIEW.md
  lands with the squash instead of dying with the worktree. For the remaining
  tasks in this flow: have the reviewer write REVIEW.md, then commit it on the
  branch as part of the review round, and only then land.

## Action items

- [x] Lesson filed: `commit-the-review-before-landing` (see LESSONS scratch / to
      be folded at Finish).
- Apply the fix backward to the queued tasks in this flow (commit REVIEW.md on
  branch pre-land).
