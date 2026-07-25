# Retro: Record epic flow in TASK.md only

- TASK: 20260725-121329
- BRANCH: master
- REVIEW ROUNDS: 1

## What went well

- The literal path sweep made the core requirement mechanical: live skill files
  now have no stale sidecar references.
- Keeping the change in one tatr task matched the user's explicit process
  preference and avoided another container for a single request.

## What went wrong

- The initial task text still allowed a task-local decision-record fallback.
  Root cause: it was seeded before the user clarified that backward
  compatibility did not matter. I corrected the executed plan before closing.
- The first Nix check failed because the sandbox could not open the normal Nix
  fetcher cache. The command passed when rerun with normal cache access.

## What to improve next time

- When the user says a compatibility path can be dropped, remove both the named
  artifact and every fallback rule that kept the old state machine alive.

## Action items

- None.
