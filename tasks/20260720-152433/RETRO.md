# Retro: Add sprout land: guarded squash-merge landing as one command

- TASK: 20260720-152433
- BRANCH: feature/sprout-land (landed as acb0ecc via sprout land itself)
- REVIEW ROUNDS: 2 (round 1 out-of-context: REQUEST_CHANGES, 1 MAJOR;
  round 2: APPROVE)

## What went well

- The out-of-context reviewer (first use as round-1 default, ahead of task
  20260720-152438 formalizing it) caught an UNFAILABLE test the implementing
  session had missed: my rollback test forced the commit failure with an
  empty index, so the reset it claimed to pin was a no-op. I had
  sabotage-tested one guard (dirty-main) and generalized confidence to the
  suite; the reviewer sabotaged a different path and broke it. Exactly the
  blind spot the review-default improvement predicts.
- Tool-over-prose promotion paid immediately: ~20 lines of race-warning
  prose left the flow skill in the same task that shipped the command, and
  this task's own landing was the command's first production run.
- Hermetic test env (fixed git identity, GIT_CONFIG_GLOBAL=/dev/null,
  init -b master) kept user config (gpgsign, defaultBranch) out of the
  suite; modeled on tatr's checker.sh.

## What went wrong

- Sabotage round 2 ran before committing the round-1 fixes; the
  `git checkout` restore reverted them along with the sabotage. Root cause:
  the A/B commit-first rule was applied at the FIRST sabotage and mentally
  marked done for the task - it triggers per sabotage, not per task. The
  suite caught it (13/14 post-restore).
- Two scripted str.replace edits on REVIEW.md silently no-opped on a
  one-character mismatch (comma vs semicolon); caught only by re-reading
  the artifact. Root cause: replace-based editing without asserting the
  match.
- The plan's DoD named `nix flake check --no-build` as a proof without
  baselining it; it is broken on untouched master (filed 20260720-153613),
  so the first verify run was spent triaging an inherited failure.

## What to improve next time

- When writing a DoD, run each cmd: proof once against the BASE branch;
  a proof that fails on the baseline is not a proof of this task.
- Scripted text replacement must assert the substring matched (or use the
  editing tool that errors on mismatch), then re-read the artifact.
- Treat "commit the fix" as the first step OF every sabotage, not a
  once-per-task box.

## Action items

- [x] docs/LESSONS.md created with this task's four lessons.
- [x] 20260720-153613 filed for the pre-existing nix flake check breakage.
