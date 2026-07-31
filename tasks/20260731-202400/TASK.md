# Report DoD proofs already green on the base branch

- STATUS: OPEN
- PRIORITY: 70
- TAGS: tatr, tooling, plan, proofs
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

As a planner, I want each `cmd:` proof run against the base branch before the
plan is approved, so a proof that is already GREEN is caught while it is still
cheap to rewrite rather than after the Story ships behind it.

## Steps

- [ ] Decide the home for the check: an `--at-base` mode on `tatr proofs`, or
      a separate subcommand. Record the choice in DECISION.md.
- [ ] Resolve the base branch the same way the rest of the flow does, and run
      each `cmd:` proof against a clean checkout of it.
- [ ] Report each proof as GREEN-AT-BASE or RED-AT-BASE. A GREEN-AT-BASE proof
      is the finding: it cannot fail for the Story, so it proves nothing.
- [ ] Decide the exit code: whether GREEN-AT-BASE is a warning or a failure,
      and whether the plan gate consumes it. Record the choice.
- [ ] Update the plan skill's proof guidance to name the command, and delete
      the prose the tool now enforces.

## Definition of Done

- The command reports which `cmd:` proofs are already green on base
  (test: a fixture task with one green-at-base and one red-at-base proof is
  classified correctly).
- The plan skill names the command instead of asking for care
  (cmd: to be written with the plan-skill change).

## Notes

- CROSS-REPO. `tatr` is an external flake input (`inputs.tatr`), not a
  directory of this repository. The implementing change lands in the tatr
  repository; this record exists so the ledger promotion has an ID in this
  tree, per the epic reference's cross-repo rule.
- Promotion target for the `baseline-dod-proofs` lesson (x3), disposition
  PROMOTE recorded 2026-07-31. The promotion-order audit chose a tool over
  skill prose because classifying a proof as already-green is mechanical and
  needs no judgement.
- Third occurrence, 20260731-174348: a proof token that read as distinctive
  (`independent`) already matched `work/verify.md`, three directories from
  anything that Story would write, so the proof was green before the branch
  existed.
- Not a child of Epic 20260731-174333. The Epic's Done Means do not depend on
  it and it is not scoped to the flow-family skill texts.
