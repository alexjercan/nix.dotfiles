# Retro: Associate sprout worktrees with task IDs

- TASK: 20260802-113805
- BRANCH: master
- REVIEW ROUNDS: 1

## What went well

Git's worktree-local config matched the ownership boundary: metadata is
available across invocations and disappears with the worktree. Tests exposed
all missing behavior before the implementation changed.

## What went wrong

The task record was created during direct implementation but its lifecycle
remained at BACKLOG until completion, requiring reconciliation afterward.

## What to improve next time

For direct-on-master tracked work, advance the task through PLANNED and WORKING
before implementation while still honoring the requested checkout strategy.

## Action items

- None. The workflow correction is recorded here; no code follow-up needed.
