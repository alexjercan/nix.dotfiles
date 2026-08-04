# Add sprout sync and land --dry-run, remember the target branch, and have compound write the landing message

- PRIORITY: 70
- TAGS: sprout, scripts, skills, afk
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE

Landing is currently three things an agent does by hand from `landing.md`:
merge the target branch into the feature branch, write the squash commit
message, then call `sprout land`. Only the message needs judgement. Move the
mechanical halves into sprout so a runner can drive them, and let `compound`
produce the message while it still has the task in context.

## sprout sync

Add `sprout sync <feature>`: merge the landing target into the feature branch
inside its worktree. This is `landing.md` step 1 as a command.

- `-n`/`--dry-run` probes with `git merge-tree --write-tree <target>
  <feature>`: no index, no worktree, no branch touched. Non-zero plus the
  conflict list when the merge would conflict.
- A conflicting real `sync` leaves the conflict in the worktree for whoever
  called it to resolve; it must not half-land anything in the main checkout.
- Already up to date is success, not an error.

## sprout land -n

Add `-n`/`--dry-run` to `land`, running every guard `cmd_land` already has
read-only: worktree exists, branch exists, not called from inside the
worktree, main checkout is on a symbolic ref, target is not the feature
itself, main checkout has no staged or modified tracked files, and the branch
is an ancestor-complete descendant of the target. Write nothing, exit non-zero
with the same message the real refusal prints.

`land` keeps refusing a branch that is not up to date. Syncing stays a
separate verb: an auto-merge inside `land` would leave a half-merged worktree
behind on conflict, and `land` is documented as atomic.

## Remember the target branch

`sprout new` branches off HEAD and records the task ID with `git config
--worktree sprout.task`. The landing target is currently re-derived at land
time from whatever branch the main checkout happens to have checked out,
which need not be what the branch was cut from. Record it the same way -
`sprout.target` on the worktree config, set at `new` from the main checkout's
current branch - and have `sync` and `land` prefer it, falling back to the
current behaviour when it is absent so existing worktrees keep working.

## compound writes the landing message

The `compound` skill closes the task with full context. Have it also record
the landing commit message - a Conventional Commit subject plus a short body,
one clean summary of the finished task, not the concatenated branch messages -
into the task record, so `sprout land -m` can be called by a script that never
read the diff. Decide where it lives (RETRO.md section or its own record) and
state it in the skill.

## Steps

Test-first: every `sprout-test.sh` case below is added and watched fail before
the `sprout.sh` change it pins.

1. [x] **`resolve_target`, and record `sprout.target` at `new`.** In
   `home/modules/scripts/sprout.sh`, add `resolve_target <worktree-path>`: print
   `git -C <wt> config --worktree --get sprout.target`, else
   `git -C "$main_worktree" symbolic-ref --quiet --short HEAD`, else print
   nothing and return non-zero. In `cmd_new`, capture the main checkout's
   current branch before creating the worktree and, when non-empty, write it to
   `sprout.target` alongside the existing `sprout.task` write - hoisting
   `git config extensions.worktreeConfig true` out of the `[[ -n $task ]]` block
   so it also runs for a plain `new`. Keep the existing rollback (remove
   worktree, delete a branch this call created) on a failed config write. A
   detached main checkout records nothing and is not an error.
   Tests: `test_new_records_target`, `test_new_detached_records_no_target`.

2. [x] **`cmd_sync`.** New function, dispatched from the bottom `case` as `sync)`.
   Signature `sprout sync <feature> [-n|--dry-run]` - feature first, flags
   after, matching `land`, because `require_feature` rejects a name starting
   with `-`. Reject any other argument with the same `unexpected argument`
   shape `cmd_land` uses. Guards: `require_feature`, worktree exists, branch
   exists, `resolve_target` resolves, target is not the feature itself.
   - `-n`: `git merge-tree --write-tree --name-only --no-messages <target>
     <feature>`. Confirmed in scratch on git 2.55.0: exit 0 with only a tree
     OID on stdout when clean; exit 1 with the OID line followed by the
     conflicting paths when not. Drop the OID line (`tail -n +2`), print the
     paths and a `would conflict` message to stderr, exit 1. Writes loose
     objects only - no ref, index or worktree.
   - real: `git -C <worktree> merge <target>` with chatter to stderr. Success
     (including "Already up to date") exits 0; a conflict exits 1 with a
     message naming the worktree path to resolve in, and the conflicted state
     is deliberately left in the worktree.
   Tests: `test_sync_merges_target`, `test_sync_already_up_to_date`,
   `test_sync_dry_run_clean`, `test_sync_dry_run_conflict`,
   `test_sync_conflict_stays_in_worktree`, `test_sync_rejects_bad_args`.

3. [x] **`land -n` and the target guard.** In `cmd_land`, accept `-n|--dry-run` in
   the existing `-m` parsing loop. Replace the inline `symbolic-ref` derivation
   with `resolve_target "$path"`, then add one guard: when the resolved target
   differs from the main checkout's current branch, refuse, naming both and
   telling the caller to check out the target (see `DECISION.md`). Keep the
   existing detached-HEAD, target-equals-feature, dirty-main and
   `merge-base --is-ancestor` guards, in order and with their current messages.
   After the last guard and before `git merge --squash`, `-n` prints
   `'<feature>' would land onto '<target>'` and exits 0. No `land_guards`
   extraction: the guards already run as one linear sequence, so `-n` is a
   single early exit rather than a second copy of every message.
   `-n` still requires `-m`, so that a green `-n` describes a call the real
   `land` would accept.
   Tests: `test_land_dry_run_ok`, `test_land_dry_run_writes_nothing`,
   `test_land_dry_run_refuses_behind`, `test_land_dry_run_requires_message`,
   `test_land_refuses_target_mismatch`, `test_land_uses_recorded_target`.

4. [x] **Usage text.** Add `sync` and the `land` `-n` form to `usage()` in
   `sprout.sh`.

5. [x] **`sprout/SKILL.md`.** Add `sprout sync <feature> [-n]` and the `land -n`
   form to the `## Commands` block, plus one `## Commands` bullet each for
   `sync` (merges the recorded target into the branch inside its worktree;
   conflicts stay there) and the recorded `sprout.target`. 254 of 400 body
   words available.

6. [x] **`flow/landing.md`.** Step 1 becomes `sprout sync <feature>` (with
   `sprout sync -n` as the probe); step 3's manual ancestry check becomes
   `sprout land -n`; step 4 reads the subject and body from the committed
   RETRO.md `## Landing message` section instead of composing them. Keep the
   inherited-red guidance in step 1 and the unchanged re-verify step 2. 466 of
   600 words available.

7. [x] **`compound/SKILL.md`.** Add the landing-message obligation to step 3 of
   `## Workflow`: after filling RETRO.md, append a `## Landing message` section
   holding a fenced Conventional-Commit subject, blank line, short body - one
   summary of the finished task, not the concatenated branch messages. Body is
   at 390 of a 400-word `phase-body-budget`, so trim existing prose to pay for
   it; `check.sh` is the arbiter.

8. [x] **Run the canonical checks** from `AGENTS.md`: `bash
   home/modules/scripts/sprout-test.sh`, `bash
   home/modules/agents/skills/check.sh`, `bash
   home/modules/scripts/afk-test.sh`, `tatr check`, `nix flake check`.

## Definition of Done

- `sprout sync <feature>` merges the resolved target into the feature branch
  inside its worktree, and reports "already up to date" as success
  (test: `test_sync_merges_target`, test: `test_sync_already_up_to_date`).
- A conflicting `sync` exits non-zero and leaves the conflict in the worktree,
  touching neither the main checkout nor the target branch
  (test: `test_sync_conflict_stays_in_worktree`).
- `sprout sync -n` exits 0 on a clean merge and non-zero with the conflicting
  paths otherwise, without creating a ref, index entry or worktree change
  (test: `test_sync_dry_run_clean`, test: `test_sync_dry_run_conflict`).
- `sprout sync` rejects a missing feature, an unknown flag, and a feature equal
  to the target (test: `test_sync_rejects_bad_args`).
- `sprout land -n` runs every existing guard, exits 0 without writing when the
  land would succeed, and exits non-zero with the real refusal message when it
  would not (test: `test_land_dry_run_ok`, test:
  `test_land_dry_run_writes_nothing`, test: `test_land_dry_run_refuses_behind`).
- `sprout land -n` still requires `-m`
  (test: `test_land_dry_run_requires_message`).
- `sprout new` records the main checkout's branch as `sprout.target`, and
  records nothing on a detached HEAD (test: `test_new_records_target`,
  test: `test_new_detached_records_no_target`).
- `land` prefers `sprout.target` over the main checkout's branch and refuses a
  mismatch, naming both (test: `test_land_uses_recorded_target`,
  test: `test_land_refuses_target_mismatch`).
- Worktrees with no `sprout.target` still land through the fallback: the whole
  pre-existing suite stays green (cmd: `bash
  home/modules/scripts/sprout-test.sh`).
- `sprout help` lists `sync` and the `land -n` form
  (cmd: `bash home/modules/scripts/sprout.sh help | grep -E 'sync|dry-run'`).
- `sprout/SKILL.md` documents `sync`, `land -n` and `sprout.target`
  (cmd: `grep -n 'sprout.target' home/modules/agents/skills/sprout/SKILL.md`).
- `landing.md` step 1 calls `sprout sync` and step 4 sources the message from
  RETRO.md (cmd: `grep -n 'sprout sync' home/modules/agents/skills/flow/landing.md`).
- `compound/SKILL.md` instructs writing the `## Landing message` section
  (cmd: `grep -n 'Landing message' home/modules/agents/skills/compound/SKILL.md`).
- Every skill text stays inside its budget and the reference graph stays intact
  (cmd: `bash home/modules/agents/skills/check.sh`).
- Repository checks pass (cmd: `nix flake check`, cmd: `bash
  home/modules/scripts/afk-test.sh`, cmd: `tatr check`).

## Notes

- `landing.md` step 1 becomes `sprout sync <feature>` for humans too.
- Verification after the merge is deliberately NOT part of this: review
  already proved the branch, and the user checks the default branch after a
  run.
- Cover the new paths in `home/modules/scripts/sprout-test.sh`.
- `DECISION.md` records the two load-bearing choices: `land` refuses a
  `sprout.target` / main-checkout mismatch rather than redirecting the land,
  and the landing message lives in a `RETRO.md` `## Landing message` section
  rather than a new tatr record kind.
- Confirmed on base (all red before the change): no `cmd_sync` or
  `sprout.target` in `sprout.sh`; no `sync` in `sprout/SKILL.md`; no
  `sprout sync` in `landing.md`; no `Landing message` in `compound/SKILL.md`.
  `sprout-test.sh` is green at 17 tests.
- Confirmed in scratch: `git merge-tree --write-tree --name-only --no-messages`
  exits 1 and prints the tree OID then the conflicting paths on a conflict,
  exits 0 with only the OID when clean (git 2.55.0); an extra `## Landing
  message` section in a scaffolded RETRO.md passes `tatr check`.
- `afk.sh` is deliberately untouched. Teaching the runner to call
  `sprout land -m` itself is what this task makes possible, not what it does.
- `ls` keeps its `BRANCH TASK PATH` columns; the target is not a column.
- Assumption: `-n` requires `-m` on `land`. A message-less `-n` reporting OK
  would describe a call the real `land` refuses. Cheap to relax later.
- Assumption: `sprout new` may write `extensions.worktreeConfig` at repo level
  on every call, not just `--task` ones - the same idempotent write `--task`
  already performs.

## Close-out

**What and why.** `sprout.sh` gained `resolve_target`, `cmd_sync`, a `sprout.target`
write at `new`, `land -n`, and a target-mismatch guard; `usage()` documents both new
forms. The doc surfaces that describe those behaviours moved with them:
`sprout/SKILL.md`, `sprout/reference.md`, `flow/landing.md`, `work/verify.md`, and
`compound/SKILL.md` (which now owes a `## Landing message` section in RETRO.md). The
landing sequence is now three mechanical commands a runner can drive, with the one
judgement call - the commit message - written by `compound` while the task is still
in context.

**Alternatives.** The two load-bearing forks are in `DECISION.md` (refuse a target
mismatch rather than redirect the land; put the message in RETRO.md rather than a new
tatr record kind). Two smaller ones taken here: no `land_guards` extraction, because
the guards are one linear sequence and `-n` is a single early exit inside it; and
`land -n` still requires `-m`, so a green dry run describes a call the real `land`
would accept.

**Difficulties.** `test_land_uses_recorded_target` cannot be written as a passing
land: the mismatch guard means a recorded target is only observable when it DIFFERS
from the main checkout's branch, so the test proves it by contrast - the land is
refused with `sprout.target` set, and succeeds through the fallback once it is unset.
`shellcheck` (which `writeShellApplication` runs at build time, and which
`nix flake check` does NOT reach) rejected the dry-run probe's `$?` test as SC2181;
rewritten as `if probe=$(...)`. The detached-HEAD guard had to move onto the main
checkout's CURRENT branch rather than the resolved target, or a worktree with a
recorded target would have reported a mismatch where it used to report the detached
HEAD.

**Evidence.** `sprout-test.sh` 17 -> 33 tests, all green. Discrimination was measured,
not assumed: the branch's test file run against `git show master:.../sprout.sh` fails
15 of the 16 new cases. The exception is `test_new_detached_records_no_target`, which
cannot discriminate - a detached main checkout records no target on either version -
so it is a regression guard for the hoisted `extensions.worktreeConfig` write, and now
asserts `sprout.task` is still recorded so it cannot pass vacuously. Round 1 found
three cases that were then non-discriminating for reasons that were NOT inherent
(`test_land_dry_run_writes_nothing` asserted no exit code, `test_sync_rejects_bad_args`
asserted no messages); both are fixed. `check.sh` clean, `afk-test.sh` 19 green,
`tatr check` clean, `nix flake check` all checks passed, `shellcheck` clean on both
scripts.

**Reflection.** The plan named each new test but never what it had to discriminate
against, which is exactly where three non-discriminating cases got through to review;
running the branch's tests against the base `sprout.sh` is cheap and would have caught
them at write time. The plan's step list otherwise survived contact intact except for
the one test name whose semantics had to change. The word budget in `compound/SKILL.md` cost four
rounds of trimming against `check.sh`; planning the trims as part of the step (as the
plan did) was what made that mechanical rather than a redesign.
