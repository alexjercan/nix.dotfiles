# Retro: Make flow stop gates explicit approval transitions

- TASK: 20260801-155024
- BRANCH: feat/flow-explicit-gates
- REVIEW ROUNDS: 2

## What went well

- One transition table kept the broad cross-skill change cohesive.
- Budget, full-suite, and sabotage checks caught weak prose before review.
- Fresh review reproduced both lifecycle failures from disk state.

## What went wrong

- The plan treated `tatr flow` as durable without checking the next
  `sprout new`; its uncommitted transition could not cross that boundary.
- Resume called `tatr` before finding the task-owning worktree.
- Two DoD commands could pass from neighboring text instead of their named
  clauses.

## What to improve next time

- Model every context cut as a persisted-state handoff, including which git
  root owns the next command.
- Split proof criteria at independently sabotageable boundaries.
- Plan-time question: can a fresh shell continue from only committed state and
  the documented discovery commands?

## Action items

- Fixed all three review findings in this task.
- Bumped `sprout-inherits-committed-head` and
  `edit-the-worktree-not-the-cwd`; moved
  `proof-must-cover-its-conjunct` to pending promotion.
- User chose PROMOTE; created follow-up task 20260801-184046.
