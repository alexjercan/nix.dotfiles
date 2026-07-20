# Review: Add sprout land: guarded squash-merge landing as one command

- TASK: 20260720-152433
- BRANCH: feature/sprout-land

## Round 1

- VERDICT: REQUEST_CHANGES
- REVIEWER: out-of-context (fresh-context subagent; prompt contained only the
  task id, branch, worktree path and review instructions - not the
  implementing session)

- [x] R1.1 (MAJOR) home/modules/scripts/sprout-test.sh:189 - the
  commit-failure rollback (the core anti-sweep mechanism) is not actually
  pinned: test_land_empty_squash_rolls_back forces the failure with an
  already-empty index, so the `git reset --merge` is a no-op in the only test
  of that path. Sabotage-verified by the reviewer: deleting the reset line
  leaves the suite 11/11 green, while a real squash + failed commit
  (`sprout land feat -m ""`) leaves `A  x.txt` staged in the main checkout.
  Suggested: add a test that fails the commit AFTER a real squash (empty -m
  message makes git commit abort); assert rc!=0, clean porcelain, master
  untouched, worktree kept.
  - Response: fixed - added test_land_commit_failure_rolls_back (real squash,
    empty -m message aborts the commit); sabotage-verified: deleting the
    reset line turns it red ("no staged state left behind"), restore turns
    the suite back to 14/14. Note: the restore step of that sabotage
    reverted the then-uncommitted R1.2/R1.4 fixes (A/B rule violation -
    sabotage before committing the fixes); the suite caught it (13/14) and
    the fixes were re-applied. Recorded for the retro.
- [x] R1.2 (MINOR) home/modules/scripts/sprout.sh:270 - land's stdout is not
  the documented single `landed <hash> <subject>` line: cmd_rm's
  `git branch -D` also writes to stdout ("Deleted branch feat (was ...)"),
  breaking the stdout-composability convention and contradicting
  docs/sprout.md. Suggested: `cmd_rm "$feature" 1>&2` in cmd_land and tighten
  test_land_happy to full-string match on stdout.
  - Response: fixed - cmd_rm output redirected to stderr inside cmd_land
    (standalone rm unchanged); test_land_happy now asserts
    '^landed [0-9a-f]+ feat: demo landed$' as the full stdout.
- [x] R1.3 (NIT) home/modules/scripts/sprout.sh:235,190 - the
  `target == feature` and missing-branch refusals are the only guards with no
  test (near-unreachable in normal use; reachable via a stale unregistered
  dir at the worktree path). Suggested: simulated-state test for each, or
  document as untested defense.
  - Response: fixed - added test_land_refuses_missing_branch and
    test_land_refuses_target_equals_feature, both via simulated stale dirs
    at the worktree path (mkdir without a branch / named like the target).
- [x] R1.4 (NIT) home/modules/scripts/sprout.sh:197 - the inside-the-worktree
  refusal is a literal `$PWD` prefix match; a symlinked route into the
  worktree evades it (and cmd_rm's optimistic `removed=true` then masks the
  failed cleanup). Suggested: compare realpath of PWD against realpath of the
  worktree path.
  - Response: fixed - the guard now compares realpath of PWD against
    realpath of the worktree path. cmd_rm's optimistic removed=true is left
    as is: land reaches cmd_rm only from outside the worktree, and
    reworking rm's reporting is out of this task's scope.
- [x] R1.5 (NIT) home/modules/scripts/sprout-test.sh - no `ls` coverage,
  though the DoD claims new/ls/show/rm unchanged (mitigated: reviewer diffed
  the extracted script against master's inline body - byte-identical for
  those commands). Suggested: one ls assertion in test_new_show_rm.
  - Response: fixed - test_new_show_rm asserts an ls line matching
    '^feat +feat +/'.

Reviewer verification notes: 11/11 suite pass reproduced; shellcheck clean;
package BUILD-OK; extraction fidelity confirmed by un-escaping master's
inline string and diffing (only additions); adversarial scenarios
(untracked-collision squash, land from sibling worktree, all refusals)
behaved as documented; close-out claims reproduced true except the R1.1
checkbox overstatement.

## Round 2

- VERDICT: APPROVE
- REVIEWER: out-of-context (same fresh-context subagent, resumed)

All five round-1 findings verified resolved against the new diff. Reviewer
re-ran the suite (14/14), repeated the R1.1 sabotage on the actual file
(reset line deleted -> exactly test_land_commit_failure_rolls_back red ->
restore -> 14/14), verified land stdout is the single landed line on a real
landing, exercised the symlink-evasion path against the realpath guard, and
confirmed the two simulated-stale-state tests pin their specific guard
messages. R1.4's partial pushback (cmd_rm reporting out of scope) accepted.
No new findings; the round-2 diff touches only sprout.sh, sprout-test.sh
and REVIEW.md.
