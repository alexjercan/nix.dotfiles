# Review: Replace afk's agent-driven gates with tatr flow and sprout land probes

- TASK: 20260803-105305
- BRANCH: refactor/afk-mechanical-gates

## Round 1

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

- [x] R1.1 (MAJOR) home/modules/scripts/afk.sh:865 - the DoD clause "a session
  that already performed the transition leaves afk skipping the execute rather
  than dying" is undelivered for two of the three gates, and the test named for
  it exercises a different state. `require_activity` (an equality that `die`s)
  runs unconditionally before `at_or_past`, so a session that ran `tatr flow`
  itself and then reported `WORK_DONE` from REVIEWING aborts the run with "is
  in REVIEWING, not WORKING" - exactly the death TASK.md's "Double advance"
  consequence says to replace with a skip. The one test that reaches the skip,
  `test_gate_already_advanced_is_a_skip` (afk-test.sh:711), seeds a BLOCKED
  dependency where `tatr flow` was refused and the cursor never moved; its
  comment "a session that performed the transition itself" describes a state
  the fixture does not build. Either consult `at_or_past` before the equality
  and add a case that seeds an overshot cursor (session runs `tatr flow` to
  REVIEWING, still reports `WORK_DONE`, gate is a skip not a death), or amend
  the DoD line and the test comment to say the equality deliberately wins for
  the two activity gates and only the held-cursor edge is a skip.
  Response: fixed in 9f7c93e, first option taken. `at_or_past` is now
  consulted BEFORE `require_activity` in `advance`, so a postcondition that
  already holds skips the execute at every gate and the equality guards only
  the gates with something left to run. `test_gate_overshoot_is_a_skip`
  seeds the moved-cursor state the old fixture did not build (session runs
  `tatr flow` to REVIEWING, still reports `WORK_DONE`) and asserts the skip,
  the absence of the death and a completed run; reverting the ordering fails
  seven of its eight assertions. Two consequences the finding did not name,
  both handled: the `NOTES_READY` arm's `require_activity` outside `advance`
  had to go, or it would have re-imposed the death on that gate alone
  (`require_record` stays ahead of `advance`, so a PLANNING task with no
  NOTES.md still dies); and two `test_failure_paths` cases seeded exactly
  the overshoot that is now a skip, so they were re-aimed at a gate reported
  from BEHIND its activity, where the postcondition is unearned.
  `test_gate_already_advanced_is_a_skip`'s comment now says it covers the
  held-cursor shape and points at the new test.
- [x] R1.2 (MINOR) home/modules/scripts/afk.sh:870 - the at-or-past branch
  skips `commit_records`, so the record edit that earned the gate stays
  uncommitted in the main checkout. `sprout land` refuses a non-pristine main
  checkout (sprout.sh:438) and the `LAND_READY` commit runs against the
  worktree root, so the dirt survives to the land and burns a woken session on
  a refusal afk could have prevented. Move the `commit_records` call at
  afk.sh:878 out of the `else` so it runs on both paths; it is already a no-op
  when nothing stages.
  Response: fixed in 9f7c93e. `commit_records` now runs after the branch on
  both paths. The subject is computed inside each branch, because "advance
  <id> to PLANNING" is a lie on a path that advanced nothing: a skipped gate
  commits `docs: record <id> at <ACTIVITY>`. `test_gate_overshoot_is_a_skip`
  asserts both the commit subject and a clean worktree afterwards.
- [x] R1.3 (MINOR) tasks/20260803-105305/TASK.md:79 - Steps 3 and 4 are ticked
  while both name `test_gate_resume_may_overshoot` as a test to update, and
  that test no longer exists in afk-test.sh. Deleting it with the resume path
  it described is defensible, but no record says so: the Close-out's Evidence
  and Reflection do not mention the removal. Strike the test from both Step
  texts and add one Close-out sentence saying it went with `--resume`.
  Response: fixed in 9f7c93e. Struck from Steps 3 and 4, and the Close-out's
  Difficulties now records that the test asserted a RESUMED session may
  overshoot, so it was deleted with the resume branch in Step 9. Step 6 is
  also unticked and its text says why, which is the process signal at the
  bottom of this round.
- [x] R1.4 (NIT) home/modules/scripts/afk.sh:789 - the comment says `PROBE_TEXT`
  is "empty after a probe that passed", but `capture_refusal` assigns stderr
  whatever the exit status, so a passing `sprout sync -n` can leave git chatter
  in it. Nothing reads it on the passing path, so this is comment-only: drop
  the clause, or clear `PROBE_TEXT` on a zero exit inside `capture_refusal`.
  Response: fixed in 9f7c93e, second option taken. `capture_refusal` clears
  `PROBE_TEXT` on a zero exit, so the comment is true and a later reader of
  the passing path cannot be handed chatter. The comment now says why: a
  command that succeeded refused nothing.
- [x] R1.5 (NIT) home/modules/scripts/afk.sh:1000 - the `prompt` report line is
  printed before the refusal is appended at :1002, so the reported prompt is
  not the prompt sent. `wake_on_refusal` already printed the refusal on the
  previous iteration, so nothing is hidden; move the `line "$C_PROMPT"` call
  below the `PENDING_UNMET` block anyway so the report and the argv agree.
  Response: fixed in 9f7c93e, with one departure. The call moved below the
  block, but it prints the prompt's first line plus `+ the gate refusal
  reported above` rather than the whole multi-line prompt: `line` pads a
  label and indents one row, so a multi-line value would break the report's
  alignment, and `wake_on_refusal` printed the refusal three lines earlier.
  The line no longer claims a prompt that is not the one sent.

Verified in this round:

- `bash home/modules/scripts/afk-test.sh` green at 25, `bash
  home/modules/scripts/sprout-test.sh` green at 33, `nix flake check` all
  checks passed, `tatr check` silent - re-run by the recording pass, matching
  the Close-out's Evidence numbers.
- Both DoD `cmd:` greps hit: afk.sh:79 and afk.nix:12.
- Re-derived independently of the reviewer: `advance`'s call order at
  afk.sh:865-878, `require_activity`'s unconditional `die` at afk.sh:694,
  `sprout land`'s dirty-main refusal at sprout.sh:438, and the absence of
  `test_gate_resume_may_overshoot` from afk-test.sh.
- No `manual:` proofs in the Definition of Done, so no pending user checks.

Process signal: Step 6 ("write the new tests red, before touching `afk.sh`") is
ticked while the Reflection states the ordering was inverted and three post-hoc
mutations stand in. The disclosure is honest and the mutations are named, so
this is not a false close-out - but a Step whose entire content is an ordering
constraint should not carry a tick when the ordering was not kept.

Process signal: TASK.md's "Consequences to handle" (double advance) and Step
10's literal ordering (`require_activity`, then the at-or-past skip)
contradict each other. The implementer followed the Step and documented the
gap in the Close-out. A plan should not carry a consequence its own Step list
forecloses.

Response to both signals: Step 6 is unticked, with its text saying the ordering
was not kept and which single test was written red. Step 10 is rewritten to put
the at-or-past skip first, so it no longer forecloses the "Double advance"
consequence it was derived from; it also records the two commit subjects.

## Round 2

- REVIEWER: out-of-context
- VERDICT: APPROVE

- [ ] R2.1 (MINOR) home/modules/scripts/afk-test.sh:790 - the assertion added
  for R1.2, `check "the record commit left the worktree clean" test -z "$(git
  -C "$XDG_CACHE_HOME/$WT_REL" status --porcelain 2> /dev/null)"`, cannot fail.
  By the time it runs the run has completed and `sprout land` removed the
  worktree (sprout.sh:487), so `git -C` fails, its stderr is discarded, the
  substitution is empty and `test -z ""` passes unconditionally. The behaviour
  R1.2 asked for is still proven, by "the skipped gate still committed the
  session's records" one line above, so this is a dead assertion rather than a
  coverage hole - but the R1.2 Response cites it as evidence, so an untrue
  claim is recorded. Drop the assertion and strike "and a clean worktree
  afterwards" from the R1.2 Response, or re-aim it at state that survives the
  land - `git -C "$REPO" status --porcelain` on the main checkout.

Verified in this round:

- Every round 1 finding is CONFIRMED fixed and ticked. R1.1: `at_or_past` runs
  before `require_activity` (afk.sh:880-897), the equality is inside the
  `else`, and `test_gate_overshoot_is_a_skip` seeds the moved cursor a side
  script created with `tatr -r "$wt" flow`. R1.2: `commit_records` is outside
  the branch (afk.sh:897), with the subject computed per path. R1.3: neither
  Step 3 nor Step 4 names `test_gate_resume_may_overshoot`; the Close-out
  records the deletion. R1.4: `capture_refusal` clears `PROBE_TEXT` on rc 0.
  R1.5: the prompt line runs after the append.
- Falsified by the reviewer: restoring `require_activity` ahead of the `if`
  fails `test_gate_overshoot_is_a_skip` alone (25/26); gating `commit_records`
  on the advance subject fails "the skipped gate still committed the session's
  records".
- Re-derived independently of the reviewer, and the load-bearing claim of
  R2.1: replacing the clean-worktree assertion with `test -d
  "$XDG_CACHE_HOME/$WT_REL"` FAILS, so the worktree really is gone at that
  point and the original assertion is vacuous.
- Re-run by the recording pass: `afk-test.sh` 26/26, `sprout-test.sh` 33/33,
  `tatr check` silent, `nix flake check` all six green - matching the
  Close-out's corrected Evidence numbers.
- No `manual:` proofs, so no pending user checks.

- R1.4's fix is untested on purpose: reverting the clear leaves 26/26 green,
  because nothing reads `PROBE_TEXT` on the passing path. Acceptable for a NIT
  whose whole content was making a comment true.

Process signal: the round 1 fix for a MINOR introduced the only new finding of
round 2, and it is the same shape - an assertion whose subject had already
disappeared. A check written to prove "nothing is dirty" is worth re-reading
for whether the thing it inspects still exists when it runs.
