# Review: Update flow skills and afk for tatr v1.0.0 lifecycle

- TASK: 20260802-223038
- BRANCH: chore/tatr-v1-lifecycle

## Round 1

- REVIEWER: out-of-context
- VERDICT: APPROVE

- [ ] R1.1 (MINOR) home/modules/scripts/afk-test.sh:598 - `lifecycle_gate`'s new
  postcondition kind has two arms and only `activity` has a failing test. The
  `gate` arm is the one DECISION.md item 2 rests on, so it deserves the same
  coverage: seed a task at PLANNING with `plan_sections` applied but no `tatr
  flow`, reply `AFK PLAN_READY $id` then an empty invocation 2, and assert the
  run exits non-zero naming the unearned gate.
- [ ] R1.2 (MINOR) home/modules/agents/skills/check.sh:349 - value-anchoring
  rule 8's MARKER is right, but it narrowed the guard: the retired `flow step`
  matched bare, while `activity: *(...)` needs the colon form. "Set the ACTIVITY
  to WORKING by hand" now escapes. Add a `to`-form alternative to MARKER, e.g.
  `activity to *(understanding|planning|working|reviewing|compounding)`, and the
  matching `resolution to *(...)`.

Verified independently, not taken from the record:

- `tatr flow` edge semantics re-derived in a scratch repository against tatr
  1.0.0: `PLANNING -> WORKING` prints `gate PLAN recorded` and lands the cursor
  in one call; `WORKING -> REVIEWING` earns nothing; `REVIEWING -> COMPOUNDING`
  earns `REVIEW`; `COMPOUNDING` earns `RETRO` and closes `RESOLUTION: DONE`
  while `ACTIVITY` stays `COMPOUNDING`. `GATES` is space-delimited
  (`- GATES: PLAN REVIEW`), which is what `phase_label`'s `${gates// /+}` and
  `require_gate`'s token match assume.
- `tatr rewind <id> --to WORKING` from REVIEWING reports `no gates cleared` and
  needs no `--force`, as `work/review-feedback.md:9` now states.
- check.sh rules 8 and 9 fire on planted clauses: `Set ACTIVITY: WORKING by hand
  in TASK.md` reports `direct-state-edit`, and an unrooted `tatr rewind` reports
  `unrooted-tatr-call`. Both plants reverted; tree clean.
- The `gate` postcondition arm behaves correctly despite being untested: an
  approved PLAN_READY that earns nothing dies with `the plan ready gate was
  approved but <id> has earned no gates, not PLAN`.
- The gate labels in `afk.sh:806,814,827` are byte-identical to the `gates.md`
  approve labels.
- Every DoD proof rerun here: afk suite 15 passed 0 failed, `check.sh` clean,
  the straggler grep empty, `nix flake check` all 6 checks passing. The
  Close-out's evidence claims are accurate.

Not findings, recorded for the retro:

- Process signal: the prerequisite flake-input bump and the 73-record migration
  landed on master outside this branch. That was the right call - a v1 tatr
  cannot load a v0 record, so the branch is unusable without it - but it means
  the branch diff alone does not show the change that made the branch buildable.
