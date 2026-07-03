# Retro: Resolve sprout project from the main worktree, not the current one

- TASK: 20260703-110225
- BRANCH: fix/sprout-project-resolution (merged to master)
- REVIEW ROUNDS: 1 (APPROVE)

See `tasks/20260703-110225/TASK.md` and `.../REVIEW.md`. Process notes only.

## What went well

- Verified the fix against the exact failure mode before writing it: probed
  `git worktree list` / `--git-common-dir` from both the main checkout and a
  worktree, saw they agreed, then chose between them on robustness grounds
  rather than guessing. One review round to APPROVE.
- The bug was already captured as its own task during the previous review, so
  picking it up was mechanical - the plan-work-review-compound trail did its
  job across cycles.

## What went wrong

- Nothing in this cycle. The underlying defect, though, was shipped in the
  core task because `--show-toplevel` was only ever tested from the main
  checkout - never from inside a worktree, which is the tool's whole point.

## What to improve next time

- Test a command from the location it will actually run, not just the
  convenient one. For a tool built to be used *inside* worktrees, "run it from
  inside a worktree" is a required test case, not an edge case.

## Action items

- [ ] Pattern watch: "too-narrow test inputs / didn't test from the real usage
      site" has now appeared in the core retro and this one. If it recurs a
      third time, promote it from AGENTS.md's general "test the feature the way
      a user would" line to a concrete shell-tool testing checklist in docs/.
