# Retro: Wire tatr check into the tatr, compound, flow and lessons skills

- TASK: 20260720-152508
- BRANCH: feature/tatr-check-skills (landed as 56cb2c6 via sprout land)
- REVIEW ROUNDS: 2 (R1 out-of-context: REQUEST_CHANGES, 1 MAJOR; R2: APPROVE)

## What went well

- Verifying documented flags against the freshly REBUILT binary (the main
  checkout's ./tatr was a stale pre-check artifact) - the DoD's
  match-the-built-tool proof would have lied against the stale binary.
- The reviewer proved the compound gate coherent (default check passes
  before RETRO.md exists), a deadlock I had not explicitly designed against.
- Contention with a live parallel session was absorbed entirely by the
  sprout land gates: dirty-main refusal (their uncommitted state), two
  behind-master refusals (they landed twice mid-cycle), one
  inside-worktree refusal (mine). Every refusal cost one retry; none
  corrupted anything.

## What went wrong

- R1.1 (MAJOR): the bare-counts convention that makes the promotion lint
  reliable was documented only in my close-out - a file no future session
  reads - while the skill told sessions to rely on the lint. Root cause:
  writing the caveat where I discovered it instead of where its reader is.
- R1.2: ticked "shrink the prose" while delivering "extend the prose" -
  second occurrence of tick-against-the-literal-step.
- Chained sprout land after in-worktree commands twice across this flow;
  the guard caught both, but the retry noise is a pattern now (x2).

## What to improve next time

- When a mechanism gets a reliance-worthy promise in a skill, put its
  enabling convention in the same paragraph, not in the shipping task's
  records.
- Land is its own call from the main checkout, always - never the tail of
  a worktree chain.

## Action items

- [x] Ledger: tick-against-the-literal-step bumped to x2;
      document-where-the-reader-reads and land-from-the-main-checkout added.
