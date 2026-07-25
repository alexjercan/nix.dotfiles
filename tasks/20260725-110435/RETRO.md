# Retro: Harden flow planning and resume gates

- TASK: 20260725-110435
- BRANCH: feature/flow-planning-resume-gates
- REVIEW ROUNDS: 1

## What went well

- Landing the tatr checker first turned the most important process rule into a
  tool guard before updating the skill prose.
- Folding the accidental child task back into the active task made this cycle
  obey the rule it was adding, not just describe it for future runs.

## What went wrong

- The initial plan created both an umbrella and a child task for one requested
  thing. Root cause: the old flow skill encoded umbrella-first behavior, so the
  planning phase followed the stale process before the user corrected it.
- The round-1 review could not use an out-of-context subagent because the
  available subagent tool requires explicit delegation authorization.

## What to improve next time

- During planning, apply the process rule being changed to the current task
  shape as soon as the user clarifies it.
- When a skill wants out-of-context review, either get explicit delegation
  authorization up front or record the in-session exception immediately.

## Action items

- [x] Added `one-request-one-task` to LESSONS.md.
