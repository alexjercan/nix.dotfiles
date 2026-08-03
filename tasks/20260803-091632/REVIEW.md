# Review: Gate understanding on a NOTES.md scratchpad the user approves

- TASK: 20260803-091632
- BRANCH: feature/understanding-notes-gate

## Round 1

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

- [x] R1.1 (MAJOR) home/modules/agents/skills/review/dimensions.md:62 - the
  docs dimension says behavior changes "are covered in the task's NOTES.md or
  the project's reference docs", which the new `flow/understanding.md:47`
  contradicts: NOTES.md "is not maintained once work starts: a stale section
  is expected there". A reviewer holding both texts flags a correctly-stale
  NOTES.md as a docs miss. The deliverable here IS skill prose, so a
  self-contradiction across two shipped skill files is a defect in the change,
  not a peripheral nit - and `dimensions.md`'s own rule ("an edit to what a
  skill describes invalidates that skill text - the sweep owed it an update in
  the same task") makes the sweep owe it. Drop NOTES.md from that sentence,
  leaving the project's reference docs as the doc surface. `DECISION.md`'s
  last Consequences bullet asserts the same false claim
  ("`review/dimensions.md` already treats NOTES.md as a documentation
  surface"); correct it in place rather than superseding the record, since the
  decision itself is unchanged.
  - Response: fixed. `review/dimensions.md` Docs now names the project
    reference docs as the doc surface and states a stale NOTES.md section is
    not a finding; `DECISION.md`'s Consequences bullet corrected in place.
- [x] R1.2 (MINOR) home/modules/scripts/afk.sh:874 - the `NOTES_READY` branch
  is the one gate whose postcondition nothing enforces: `tatr` grants
  UNDERSTANDING -> PLANNING unconditionally, so `lifecycle_gate ... activity
  PLANNING` passes for a session that wrote no `tasks/<id>/NOTES.md` and
  merely ran `tatr flow` twice. Under afk the new gate then degrades to a bare
  stop - the failure mode DECISION.md rejects the inline-confirmation
  alternative for. The other two gates get their teeth from `tatr` refusing
  the transition; this one has to bring its own. Add a postcondition check
  that `tasks/<id>/NOTES.md` exists before the branch reports success, and a
  `test_failure_paths` case for its absence (the happy-path fixture writes
  one, so nothing currently falsifies it).
  - Response: fixed. `afk.sh` gained `require_record`, called as a NOTES_READY
    precondition alongside an explicit `require_activity` so a task past
    UNDERSTANDING still reports the state disagreement first. `afk-test.sh`
    gained the missing-NOTES.md case and `write_notes`; deleting the
    `require_record` call fails both new checks.
- [x] R1.3 (MINOR) home/modules/agents/skills/flow/epic.md:48 - "an epic runs
  the same five activities", so an EPIC container now stops at `NOTES_READY`
  and is asked for `## Data and interfaces` and `## Sketches` it has no code
  for. `epic.md:17` already lists the gates an EPIC skips; add `NOTES_READY`
  to that list, or state in `understanding.md` that an EPIC writes only What
  changes, Surfaces, and Consequences.
  - Response: fixed. `epic.md` now lists understanding among the gates an EPIC
    skips, with the reason.
- [x] R1.4 (MINOR) home/modules/agents/skills/flow/understanding.md:14 - step 4
  returns `NOTES_READY` unconditionally, but reading the tree is exactly where
  the router's `WHAT unknown -> spike` row is discovered. Add one clause to
  step 2: if WHAT is still unknown after reading, return to the router's
  `spike` route instead of writing NOTES.md.
  - Response: fixed. `understanding.md` step 2 routes an unknown WHAT to
    `spike` and writes no NOTES.md.
- [x] R1.5 (NIT) home/modules/scripts/afk-test.sh:303 - `[[ $1 == UNDERSTANDING
  ]] || tatr flow ...` parks any unrecognized argument at PLANNING, so a typo
  in a future caller yields a green test against the wrong fixture. Make it a
  `case` over `UNDERSTANDING|PLANNING` with a failing `*)` arm.
  - Response: fixed. `seed_task_at` is a `case` with a failing default;
    typoing the argument now fails the run instead of seeding PLANNING.
- [x] R1.6 (NIT) home/modules/agents/skills/flow/SKILL.md:10 - the budget trim
  dropped "For an existing ID", so "Resolve ID, else `tatr new`. `resume.md`
  selects `<task-root>`" now reads as unconditional and is contradicted by the
  next clause. Restore the condition within budget, e.g. "An existing ID:
  `resume.md` selects `<task-root>`; a new one has none, so use main."
  - Response: fixed. `flow/SKILL.md` restores the condition, landing at
    300/300 body words.

Process signal: label drift between `gates.md` and `afk.sh` is still caught
only by hand-written string literals in `afk-test.sh` plus a one-shot DoD
grep. The fourth label inherits that gap rather than widening it, but a check
that reads the labels out of `gates.md` would retire a class of
unattended-run breakage.

Process signal: the DoD's six-section proof (`grep -c '^## '
understanding.md >= 6`) is satisfied by the fenced template alone - it stays
green if every section description is deleted. TASK.md says so honestly, but
the proof is shape-only.

Verified by the recording pass, in the worktree: `check.sh` exit 0 ("clean, 8
skills, 23 rules, 152 flow-family description words"); `afk-test.sh` exit 0,
19/19; `tatr check` exit 0; `nix flake check` exit 0, 6 checks. The
out-of-context reviewer additionally recomputed every word budget with
check.sh's own `body_of` (flow/SKILL.md 298/300, plan/SKILL.md 400/400,
understanding.md 291/600, gates.md 327/600, resume.md 513/600 - all match
TASK.md), and falsified the new tests by deleting the `NOTES_READY` branch
from `afk.sh` (5 of 19 fail) and `understanding.md` (check.sh
`broken-reference`). The recording pass independently re-derived R1.1, R1.2,
R1.3 and R1.6 against the files and `lifecycle_gate`'s contract.

Pending user checks: the open `manual:` DoD item - a real `/flow` run
producing a NOTES.md a cold reader can act on - is not verifiable from the
branch and does not block the verdict.

## Round 2

- REVIEWER: out-of-context

Every round-1 finding verified against the code and ticked. The
`require_record` falsification was reproduced independently in a scratch copy:
deleting the two-line call fails `the missing scratchpad is named` and `the
unbriefed gate was never answered` (18/19). Budgets recomputed with check.sh's
own rules: `flow/SKILL.md` 300/300, `plan/SKILL.md` 400/400,
`review/dimensions.md` 600/600, `understanding.md` 310/600, `gates.md`
327/600, `resume.md` 513/600, `epic.md` 328/600. `check.sh`, `afk-test.sh`
(19/19), `tatr check` and `nix flake check` all exit 0.

- VERDICT: REQUEST_CHANGES

- [x] R2.1 (MAJOR) tasks/20260803-091632/TASK.md:141 - the round-1 fixes
  falsified three numbers the same commit left standing. DIFFICULTIES says
  `flow/SKILL.md` "gave up ... `For an existing ID`" and "Final: 298/300 and
  400/400", but R1.6 restored that clause and the body is now 300/300;
  Close-out:123 says "`flow/understanding.md` (291 words)" when R1.4's clause
  put it at 310. A recorded number that no longer matches the tree is an
  honesty defect, not a typo. Drop the "For an existing ID" clause from that
  bullet, change 298/300 to 300/300, and change 291 to 310.
  - Response: fixed. Close-out now says 310 words for `understanding.md`, the
    DIFFICULTIES bullet drops the restored "For an existing ID" clause, and
    both bodies are recorded at their exact 300/300 and 400/400.
- [x] R2.2 (NIT) home/modules/scripts/afk-test.sh:693 - of the three checks the
  new NOTES.md case adds, `test "$rc" -ne 0` is not falsifiable: with
  `require_record` deleted the run still exits non-zero, because session 2 has
  no scripted reply and afk dies on the missing control marker instead. It
  passes for the wrong reason. Assert the exit path rather than the status, or
  drop the check and keep the two that do falsify.
  - Response: fixed. The `rc -ne 0` check is gone, with a comment naming why
    it could not falsify; the failure reason and the invocation count remain.

## Round 3

- REVIEWER: out-of-context
- VERDICT: APPROVE

Both round-2 findings verified and ticked. `TASK.md`'s close-out numbers were
recomputed against the tree rather than read: `understanding.md` 310 whole-file
words, `flow/SKILL.md` 300/300 and `plan/SKILL.md` 400/400 by check.sh's
`body_of`, and the surviving trim claims were checked against `git show
master:` copies - "load `gates.md` and follow it" and "flow owns the approval
gate" are genuinely gone. The R2.2 falsification was reproduced in a scratch
copy: with `require_record` deleted, 18/19 with exactly `the missing scratchpad
is named` and `the unbriefed gate was never answered` failing. No regressions
from either fix. `check.sh`, `afk-test.sh` (19/19), `tatr check` and `nix flake
check` all exit 0.

- [ ] R3.1 (NIT) tasks/20260803-091632/TASK.md:112 - the `## Notes` bullet
  reads "Two budgets have almost no headroom (`flow/SKILL.md` 299/300,
  `plan/SKILL.md` 398/400)" in the present tense, but both bodies are now at
  their limits. Left open deliberately: those are plan-time figures, they match
  master and the Steps that quote them, and DIFFICULTIES records the post-change
  values - so the record is internally coherent. Put the bullet in the past
  tense if a later task touches it.

Pending user checks: the open `manual:` DoD item - a real `/flow` run producing
a NOTES.md a cold reader can act on.
