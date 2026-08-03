# Review: Add sprout sync and land --dry-run, remember the target branch, and have compound write the landing message

- TASK: 20260803-105234
- BRANCH: feature/sprout-sync-land-dry-run

## Round 1

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

Checks re-run by the recording pass in the worktree, all green: `sprout-test.sh`
31/31, `check.sh` clean, `afk-test.sh` 19/19, `tatr check`, `nix flake check`.
Re-derived independently: the branch's `sprout-test.sh` run against
`git show master:home/modules/scripts/sprout.sh` fails 11 of the 14 new cases
and passes 3, which is R1.1.

- [x] R1.1 (MAJOR) home/modules/scripts/sprout-test.sh:261 - three of the
  fourteen new cases pass unmodified against master's `sprout.sh`, so they pin
  nothing. `test_land_dry_run_writes_nothing` (:261) never asserts an exit
  code, so old `land` rejecting `--dry-run` as an unexpected argument satisfies
  all four asserts; `test_sync_rejects_bad_args` (:225) passes because old
  `sprout` rejects `sync` as an unknown command, so it cannot tell "sync
  rejects bad args" from "sync does not exist"; `test_new_detached_records_no_target`
  (:131) is vacuous on code that records no target. The DoD names the first two
  as its proof for "writes nothing" and "rejects bad args", so those DoD lines
  are currently unproven. Assert `rc -eq 0` in `test_land_dry_run_writes_nothing`;
  assert the specific stderr in `test_sync_rejects_bad_args` (`unexpected
  argument`, `no worktree`, `own landing target`); for the detached case assert
  `sprout.task` is still recorded so the test cannot pass without the config
  write running.
  - Response: fixed. `test_land_dry_run_writes_nothing` now asserts `rc -eq 0`
    first; `test_sync_rejects_bad_args` asserts an rc AND the specific stderr
    for each of its four cases (`missing <feature>`, `unexpected argument
    '--force'`, `no worktree`, `own landing target`);
    `test_new_detached_records_no_target` now passes `--task` and asserts
    `sprout.task` is recorded, so the config write must run. Re-measured
    against `git show master:...sprout.sh`: 15 of the 16 new cases now fail
    there. `test_new_detached_records_no_target` still passes on master and
    inherently cannot do otherwise - neither version records a target on a
    detached checkout - so it stands as a regression guard for the hoisted
    `extensions.worktreeConfig` write, stated as such in the Close-out.
- [x] R1.2 (MAJOR) tasks/20260803-105234/TASK.md:241 - the Close-out's Evidence
  says "each new case watched fail first for its intended reason". R1.1 shows
  that is false for 3 of the 14. Correct the sentence to state which cases were
  red and why the others were not, once R1.1's tests are strengthened.
  - Response: fixed. The Evidence paragraph now reports the measured
    base-version run (15 of the 16 new cases red), names the one case that
    cannot discriminate and why, and records that round 1 found three that were
    non-discriminating for fixable reasons.
- [x] R1.3 (MINOR) home/modules/scripts/sprout.sh:325 - `cmd_sync` guards that
  `refs/heads/$feature` exists but never the resolved target, and both merge
  paths report every failure as a conflict. With the recorded `sprout.target`
  branch deleted or renamed, `sprout sync feat` prints "conflicted; resolve it
  in <path>, then commit" and `sync -n` prints "would conflict", sending the
  caller to resolve a conflict that does not exist; the same catch-all fires
  when `git merge` refuses for an unrelated reason. Add a
  `git show-ref --verify --quiet "refs/heads/$target"` guard mirroring the
  feature-branch one at :297, and gate the resolve-it message on
  `git -C "$path" ls-files -u` being non-empty.
  - Response: fixed. `cmd_sync` now guards `refs/heads/$target` with the same
    `show-ref` shape as the feature branch, refusing with "no target branch
    '<target>' for '<feature>'" and naming the `--unset sprout.target` escape;
    the guard sits before the dry-run branch, so `-n` refuses identically. The
    real merge's failure message is gated on `git -C "$path" ls-files -u`, and
    any other failure now reports "failed in <path>" instead of a conflict.
    Pinned by `test_sync_refuses_missing_target`, which asserts both paths and
    that the word "conflict" is absent.
- [x] R1.4 (MINOR) home/modules/scripts/sprout.sh:325 - `git -C "$path" merge
  "$target"` merges into the worktree's HEAD, not into `refs/heads/$feature`.
  In a detached sprout worktree - a state `ls` explicitly renders as `-` -
  `sync` reports success while the feature branch is untouched, and the failure
  only surfaces later as `land`'s "not up to date" refusal. After the
  branch-exists guard, require `git -C "$path" symbolic-ref --quiet --short
  HEAD` to equal `$feature`, refusing with a message naming the detached
  worktree.
  - Response: fixed. After the target guards, `sync` requires
    `symbolic-ref --quiet --short HEAD` in the worktree to equal `$feature` and
    otherwise refuses naming the worktree path and what it is actually on
    (`a detached HEAD` when the ref does not resolve). Applies to `-n` too, so
    the probe stays a faithful predicate of the real sync. Pinned by
    `test_sync_refuses_detached_worktree`.
- [x] R1.5 (NIT) home/modules/scripts/sprout.sh:425 - `land`'s ancestry refusal
  still says "merge '$target' into it in the worktree, re-verify, then land".
  Every doc surface moved to `sprout sync`, but the message an operator
  actually hits did not. Name `sprout sync <feature>` in it.
  - Response: fixed. The refusal now reads "run 'sprout sync <feature>',
    re-verify, then land"; `test_land_refuses_behind` asserts the command
    string.
- [x] R1.6 (NIT) home/modules/scripts/sprout.sh:317 - the two new dry runs
  disagree on channel: `sync -n`'s success line goes to stderr, `land -n`'s
  (:432) to stdout. Print `sync -n`'s success line on stdout too.
  - Response: fixed. The clean-probe line goes to stdout;
    `test_sync_dry_run_clean` now captures stdout and asserts it.
- [x] R1.7 (NIT) home/modules/agents/skills/compound/SKILL.md:15 - the budget
  trim dropped "explicitly" from "stop unless the user explicitly requests an
  unfinished retro", weakening the guard against a vague ask producing a retro
  on an unreviewed task. Restore the word and pay for it elsewhere.
  - Response: fixed. "explicitly" restored; paid for by trimming "measured or
    observed context pressure" to "observed" in the Diagnose section. `check.sh`
    clean at the 400-word phase budget.
- [x] R1.8 (NIT) home/modules/agents/skills/sprout/SKILL.md:33 - "`new` also
  records the branch it was cut from" is inaccurate on two paths: a reused
  existing branch records the main checkout's current branch, not where that
  branch diverged, and a detached main checkout records nothing. Nothing
  documents the escape when a recorded target is later renamed or deleted -
  `land` refuses permanently and the remedy is `git config --worktree --unset
  sprout.target`. Add half a sentence for the fallback/unset case here or in
  `landing.md`'s troubleshooting list.
  - Response: fixed. The bullet now says `new` records the main checkout's
    CURRENT branch, that a detached one records nothing, and that a renamed or
    deleted target makes both `sync` and `land` refuse until
    `git config --worktree --unset sprout.target`. Kept in `sprout/SKILL.md`
    rather than `landing.md`: `sync` hits it too, and that is not a landing
    surface.

Spec: every Step and DoD line is satisfied by the diff and every DoD `cmd:`
proof was re-run green; R1.1 is about two of those proofs not discriminating,
not about the behaviour being absent. `landing.md` sources the landing message
in its step 3 rather than the plan's step 4 - functionally equivalent, not a
finding.

Design: no finding. `resolve_target` plus a compare-don't-redirect guard is the
only shape that keeps `land` atomic given `git merge --squash` commits onto the
main checkout's HEAD, and `DECISION.md` argues it. Declining the `land_guards`
extraction is right: `-n` is one early exit in a linear sequence.

Process signal: the plan's step list survived contact intact, but the plan
named the new tests without stating what each must discriminate against - which
is exactly where the three non-discriminating cases got through.

## Round 2

- REVIEWER: out-of-context
- VERDICT: APPROVE

All eight round-1 findings verified fixed and ticked. Checks re-run by the
recording pass in the worktree, all green: `sprout-test.sh` 33/33, `check.sh`
clean (8 skills, 23 rules, 152 flow words), `afk-test.sh` 19/19, `tatr check`,
`nix flake check`. Discrimination re-measured against
`git show master:home/modules/scripts/sprout.sh`: 16 of the 33 cases red there -
the 15 new discriminating cases plus the modified `test_land_refuses_behind`.
The one new case green on master, `test_new_detached_records_no_target`, cannot
discriminate for the inherent reason TASK.md states, so its Evidence claim of
"15 of the 16 new cases" is accurate.

Re-derived independently: R2.1. `git merge-tree --write-tree --name-only
--no-messages` on unrelated histories exits 128 with empty stdout and its own
stderr, which is what makes the probe's catch-all misreport.

R1.3 is ticked because both changes it asked for landed; R2.1 is the same
class of defect on the path it did not name, not a regression.

- [ ] R2.1 (MINOR) home/modules/scripts/sprout.sh:331 - the R1.3 fix reached
  only the real merge path; the dry run still treats any non-zero `merge-tree`
  as a conflict. Confirmed in scratch: on unrelated histories `merge-tree`
  exits 128 with empty stdout, so `sprout sync <feature> -n` prints a blank
  line and "would conflict" where the real `sync` now correctly says "failed".
  Capture the probe's stderr, and print the "would conflict" line only when the
  probe exited 1 with a non-empty path list; otherwise print the `failed`
  wording and the probe's own error.
  - Response:
- [ ] R2.2 (NIT) tasks/20260803-105234/TASK.md:246 - the corrected Evidence
  paragraph contradicts itself: "Round 1 found three cases that were then
  non-discriminating for reasons that were NOT inherent" names two and says
  "both are fixed", while the sentence before it classifies the third as
  inherently non-discriminating. Reword to "Round 1 found two cases
  non-discriminating for non-inherent reasons ... both are fixed; the third it
  flagged is the inherent case above."
  - Response:
- [ ] R2.3 (NIT) home/modules/scripts/sprout-test.sh:288 - `check "the dry run
  refuses too" not quiet sprout sync feat -n` pins only an exit code, so it
  cannot tell the detached-HEAD refusal from any other refusal. Capture stderr
  and assert it names the worktree path, matching the real-run assertion two
  lines above.
  - Response:

No open BLOCKER or MAJOR, so these three do not block. No pending `manual:`
items.
