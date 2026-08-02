# Update flow skills and afk for tatr v1.0.0 lifecycle

- PRIORITY: 20
- TAGS: chore, tooling
- KIND: TASK
- ACTIVITY: WORKING
- GATES: PLAN
- RESOLUTION: -

tatr v1.0.0 replaced the single `FLOW STEP` chain with three independent
fields - `ACTIVITY` (a nullable cursor), `GATES` (an accumulating set) and
`RESOLUTION` (nullable, terminal) - and dropped `tatr flow --to`. Every
consumer in this repository still speaks v0: the flow-family skills name
`PLANNED`/`DONE` as states and pass `--to`, `check.sh` rule 8 guards the
retired marker names, and `afk.sh` reads `- FLOW STEP: ` out of `tatr show`
and asserts single-word states around each gate. The afk suite is red (1
passed, 14 failed on `unknown argument: --to`).

The lifecycle facts this task is written against, all confirmed against
tatr 1.0.0 in a scratch repository:

- `tatr flow <id>` advances exactly one activity and runs that activity's exit
  gate. `PLANNING -> WORKING` earns `PLAN`, `REVIEWING -> COMPOUNDING` earns
  `REVIEW`, `COMPOUNDING` earns `RETRO` and closes as `RESOLUTION: DONE` in one
  motion. `WORKING -> REVIEWING` earns nothing.
- Leaving `PLANNING` may half-succeed: with an open dependency or a foreign
  claim tatr prints `gate PLAN recorded`, holds the cursor at `PLANNING` and
  exits 1. The gate is the durable half.
- Backward movement is `tatr rewind <id> --to <ACTIVITY>`, which runs no gate
  and clears the gates at or after the target; `--force` only when the record
  actually carries one. `REVIEWING -> WORKING` after `REQUEST_CHANGES` carries
  no `REVIEW` gate, so no `--force`.
- `tatr close <id> --resolution WONTDO|DUPLICATE|SUPERSEDED` replaces
  `flow --to DROPPED`. `STATUS` is derived, never stored.
- An EPIC walks the same five activities; its gates skip the record-presence
  checks, so `tatr flow <epic-id>` repeated to closure is how an epic ends.

## Steps

- [ ] On master, before sprouting: commit the already-staged-in-worktree tatr
      input bump (`flake.nix`, `flake.lock`, v0.2.2 -> v1.0.0) together with
      the `tatr migrate --apply` output over `tasks/` (73 records). The sprout
      worktree branches off HEAD, and tatr v1 refuses to load a v0 record, so
      the branch is unusable until this lands. Verify with `tatr check` clean
      and `git status --porcelain` empty apart from this task.
- [ ] `home/modules/scripts/afk.sh`: replace `flow_step()` with a generic
      `task_field()` (`$1` id, `$2` field name) reading `- <FIELD>: ` from
      `tatr -r <root> show`, mapping tatr's `-` placeholder to the empty
      string, plus one-line `task_activity`, `task_gates` and
      `task_resolution` wrappers over it. Add `task_exists()` using the exit
      status of `tatr show`, because a task with no activity is a real task
      and the old `[[ -n $(flow_step ...) ]]` existence test no longer holds.
- [ ] `afk.sh`: add `phase_label()` (`$1` id) returning what a human should
      see - `DONE` when a resolution is set, else the activity with its gates
      appended in tatr `frontier` style (`WORKING+PLAN`), and `OPEN` when
      there is no activity yet. Rewrite `phase_gloss()` to key off that
      label's activity part: drop `PLANNED`, keep the five activities, and
      gloss `DONE` as `finished, ready to land` and `OPEN` as `not started`.
- [ ] `afk.sh` `report_phase()`: print `phase_label` and its gloss, and set
      `SPIN_PHASE` from the same label.
- [ ] `afk.sh`: replace `require_step()` with `require_activity()` (`$1` id,
      `$2` activity, `$3` claimant) and `require_gate()` (`$1` id, `$2` gate
      name, `$3` claimant), the latter matching a whitespace-delimited token
      inside `GATES`. Add `require_resolution()` for the landing gate. Every
      one dies with the same shape of message as today, naming what the record
      actually says.
- [ ] `afk.sh` `lifecycle_gate()`: take the precondition as an activity and
      the postcondition as a gate name rather than two `FLOW STEP` values.
      `PLAN_READY` becomes: activity `PLANNING` before, gate `PLAN` after -
      the gate, not the cursor, because a plan gate that half-succeeds on a
      blocked dependency still earned `PLAN` and the run must not call that a
      lie. `WORK_DONE` becomes: activity `WORKING` before, activity
      `REVIEWING` after, since that edge earns no gate; give the helper a
      postcondition kind (`gate` or `activity`) rather than duplicating it.
- [ ] `afk.sh` `cmd_run()`: `LAND_READY` requires `RESOLUTION: DONE` instead
      of `FLOW STEP: DONE`; the two `[[ -n $(flow_step ...) ]]` existence
      checks become `task_exists`; the `step=$(flow_step ...)` spinner
      priming uses `phase_label`.
- [ ] `afk.sh` `fingerprint()`: hash the activity, the gates and the
      resolution instead of the single step, so a session that only earned a
      gate still counts as durable progress.
- [ ] `afk.sh`: update the gate labels passed to `gate()` so they stay
      byte-identical to the new `gates.md` approve labels, and update
      `usage()` ("current flow step" -> "current activity") and the header
      comment block that describes what afk cross-checks.
- [ ] `home/modules/agents/skills/flow/gates.md`: the `PLAN_READY` row becomes
      `Approve plan - earn the PLAN gate` running `tatr -r <task-root> flow
      <id>`, and `WORK_DONE` becomes `Approve review - move to REVIEWING`
      running the same bare command. Note that leaving `PLANNING` lands the
      cursor in `WORKING`, and that a held cursor with `PLAN` earned is a
      blocked dependency, not a failed approval.
- [ ] `flow/SKILL.md`: rewrite the route table in v1 vocabulary - no activity
      -> UNDERSTANDING; `PLANNING` -> `plan` -> PLAN_READY gate; `WORKING`
      with `PLAN` earned -> `work`; `REVIEWING` -> `review`; `REVIEWING` +
      REQUEST_CHANGES -> `work` (rewind); `COMPOUNDING` -> `compound`;
      `RESOLUTION: DONE` + branch -> LAND_READY. Drop `PLANNED`, `BACKLOG` and
      `DONE` as states and every `--to`. Keep the file inside its check.sh
      budget.
- [ ] `flow/resume.md`: dispatch from ACTIVITY plus GATES, not FLOW STEP; the
      `DONE` route becomes the closed record; the "committed APPROVE still in
      REVIEWING" and "committed retro in COMPOUNDING" reconstructions name
      `tatr flow <id>`; the report line names activity and gates.
- [ ] `flow/epic.md`: `flow <epic-id> --to DONE` becomes walking the epic to
      closure with `tatr -r <task-root> flow <epic-id>`; mention `tatr close
      --resolution WONTDO|SUPERSEDED --reason ...` for retiring a child.
- [ ] `work/SKILL.md` step 2: drop `tatr flow <id> --to WORKING` - the
      approved plan gate already moved the cursor there - and instead confirm
      the record reads `ACTIVITY: WORKING` with `PLAN` earned before
      implementing, stopping if the cursor was held at `PLANNING`.
- [ ] `work/review-feedback.md`: the REVIEWING -> WORKING move becomes `tatr
      -r <task-root> rewind <id> --to WORKING`, and the handoff back becomes
      `tatr -r <task-root> flow <id>`.
- [ ] `review/SKILL.md` and `review/rounds.md`: the APPROVE handoff becomes
      `tatr -r <task-root> flow <id>` (which earns `REVIEW`); the
      `approve-with-open-findings` sentence names `tatr flow` out of
      `REVIEWING` rather than `flow --to COMPOUNDING`.
- [ ] `compound/SKILL.md`: the finish becomes `tatr -r <task-root> flow <id>`,
      which earns `RETRO` and closes the task as `DONE` in one motion.
- [ ] `plan/SKILL.md` step 5: the approval records itself through `tatr -r
      <task-root> flow <id>`; planning still leaves the lifecycle alone.
- [ ] `home/modules/agents/skills/check.sh` rule 8: replace the retired
      `flow step|plan status` marker vocabulary with the v1 markers -
      `activity: <one of the five>`, `gates: <plan|review|retro>`,
      `resolution: <done|wontdo|duplicate|superseded>` - keeping the existing
      `status: open|in_progress|closed` arm. Value-anchored, so the ordinary
      English words "gates" and "activity" cannot trip the rule. Update the
      rule's comment block, which quotes `FLOW STEP` throughout, and
      `skills/README.md` where it names the same rule.
- [ ] `check.sh` rule 9: add `rewind` and `close` to `TATR_ID_SUBS`, so the
      new backward move and the retire path are held to `-r <task-root>` like
      every other task-taking call.
- [ ] `home/modules/scripts/afk-test.sh` fixtures: rewrite the four side
      effect scripts and the two task builders that drive tatr - every
      `flow --to X` becomes a bare `tatr flow`, the PLANNED task builder walks
      to `WORKING`, the RETRO scaffold plus `--to DONE` becomes one `tatr
      flow`, and the REVIEW.md fixture keeps satisfying the REVIEW gate.
      `task_step()` becomes a field reader matching afk's.
- [ ] `afk-test.sh` expectations: the phase lines assert the new labels
      (`WORKING+PLAN`, `REVIEWING+PLAN`, `DONE`), the gate argv assertions
      assert the new approve labels, the landed-task assertion checks
      `RESOLUTION: DONE`, the spinner regex tracks the new phase word, and the
      wrong-state gate case (`PLAN_READY` at an already-advanced task) still
      fails the run.
- [ ] Sweep for stragglers: `grep -rn 'FLOW STEP\|PLAN STATUS\|--to \(PLANNED\|WORKING\|REVIEWING\|COMPOUNDING\|DONE\|DROPPED\)' home/modules/agents/skills home/modules/scripts` must be empty, then run the three checks in the DoD.

## Definition of Done

- The afk suite is green against tatr 1.0.0.
  (cmd: `bash home/modules/scripts/afk-test.sh`)
- afk reports a task's phase as its activity plus its earned gates, and routes
  the landing gate off `RESOLUTION: DONE`.
  (test: `test_run_report_reads_as_a_report`)
- A gate whose durable postcondition did not land still fails the run.
  (test: `test_failure_paths`)
- No skill or script still names a retired lifecycle word or passes `--to` to
  `tatr flow`.
  (cmd: `! grep -rn 'FLOW STEP\|PLAN STATUS\|flow <id> --to\|flow "$id" --to' home/modules/agents/skills home/modules/scripts`)
- The skills conformance gate stays green, with rule 8 guarding the v1 marker
  names. (cmd: `bash home/modules/agents/skills/check.sh`)
- The repository checks stay green. (cmd: `nix flake check`)

## Notes

- Baseline before the change: `bash home/modules/scripts/afk-test.sh` reports
  `passed: 1  failed: 14`, every failure downstream of `unknown argument:
  --to`. `bash home/modules/agents/skills/check.sh` is green - rule 8 passes
  today because it guards words nothing writes any more, which is exactly the
  regression this task closes.
- The flake input bump and the record migration are already in the working
  tree, unstaged, from the user's upgrade. They are a prerequisite commit, not
  part of the feature branch's diff.
- Decision to record in DECISION.md: the plan gate's approval now performs
  `PLANNING -> WORKING` in one call, so `work` no longer transitions anything.
  The alternative - having `work` walk the cursor - is not available: `flow`
  is the sole gate writer and the `PLAN` gate is earned by leaving `PLANNING`.
  The consequence is that the WORKING transition is committed in the main
  checkout before the sprout worktree exists, which is consistent with
  `gates.md` already committing task records before the context cut.
- Second decision: afk's post-plan-gate assertion is the `PLAN` gate, not the
  `WORKING` cursor, so a planned-but-blocked task is reported honestly. The
  run then stops on the existing no-progress fingerprint rather than looping.
- Rule 9 (`unrooted-tatr-call`) enumerates its subcommands in
  `TATR_ID_SUBS='flow|scaffold|check|proofs|context|show|edit'`. `rewind` and
  `close` are new task-taking, root-sensitive subcommands and must join that
  list, or the skills' new backward move escapes the rule.
