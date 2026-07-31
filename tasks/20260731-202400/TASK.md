# Run a task's proofs safely: at-base reporting and a clean-tree sabotage guard

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
- [ ] Add the sabotage guard: refuse to mutate a proof's target while
      `git status --porcelain` is non-empty, and say why - a sabotage restore
      targets HEAD, so uncommitted edits are what it would destroy.
- [ ] Update the plan and work skills' proof guidance to name the commands,
      and delete the prose the tool now enforces.

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
- Promotion target for TWO lessons, both PROMOTE recorded 2026-07-31:
  `baseline-dod-proofs` (x3) and `commit-before-every-sabotage` (x3). Both
  audits chose a tool over skill prose - classifying a proof as already-green
  and detecting a dirty tree are mechanical and need no judgement. They share
  this task because both are "run a task's `cmd:` proofs against a known tree
  state"; splitting them would split one seam.
- `commit-before-every-sabotage` recurred three times in Epic 20260731-174333
  alone, twice destroying committed-pending review fixes. Prose has failed to
  prevent it three times, which is what moved it to a tool.
- Third occurrence, 20260731-174348: a proof token that read as distinctive
  (`independent`) already matched `work/verify.md`, three directories from
  anything that Story would write, so the proof was green before the branch
  existed.
- Not a child of Epic 20260731-174333. The Epic's Done Means do not depend on
  it and it is not scoped to the flow-family skill texts.
