# Retro: Flow skill: step 1 creates an umbrella task with GOAL.md

- TASK: 20260720-152451
- BRANCH: feat/flow-goal-artifact
- REVIEW ROUNDS: 1 (out-of-context APPROVE)

## What went well

- The task dogfooded its own artifact: the umbrella `GOAL.md`
  (20260720-152427) already existed as a live example, so the format block
  was reconciled against a real file instead of invented. The reviewer's
  manual DoD ("this flow's GOAL.md matches the prescribed format") was a
  two-way check that both sides passed.
- Anticipating the reviewer paid off: I added the step-3 umbrella carve-out
  ("the priority-0 goal umbrella is not a work task - skip it here") before
  launching the reviewer, so the two interaction concerns it was briefed to
  probe (OPEN umbrella vs. the pick loop; vs. the Finish termination) came
  back already handled. One round to APPROVE.
- Keeping the carve-out edit uncommitted until after the reviewer ran kept
  its file:line references stable against the committed diff.

## What went wrong

- Two Edit calls targeted the main-checkout path instead of the sprout
  worktree path (`/home/alex/personal/nix.dotfiles/...` vs.
  `/home/alex/.cache/sprouts/.../feat/flow-goal-artifact/...`), failing with
  "File does not exist" / "File has not been read yet". Root cause: the shell
  cwd resets to the main checkout between Bash calls, and I let that leak into
  the Edit path. No harm (the edits retried correctly) but it cost round-trips.

## What to improve next time

- When working on a sprout branch, bind the worktree path to a variable at the
  top and use it for every Edit/Read - the shell cwd reset makes relative or
  main-checkout paths a standing trap.

## Action items

- [x] Fixed R1.1 NIT in the same round (GOAL.md header fields are hand-written).
- [ ] No follow-up tatr tasks: this was a self-contained docs change.
