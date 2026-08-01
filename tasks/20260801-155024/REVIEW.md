# Review: Make flow stop gates explicit approval transitions

- TASK: 20260801-155024
- BRANCH: feat/flow-explicit-gates

## Round 1

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

- [x] R1.1 (BLOCKER) home/modules/agents/skills/flow/gates.md:19 - PLAN_READY
  approval changes TASK.md, then cuts context without committing. `sprout new`
  branches from HEAD, so the approved PLANNED state is absent from the new
  worktree. Commit the transition before the cut and pin this handoff.
  - Response: Fixed in this commit. Approval now commits only task records
    after the transition and before the context cut.
- [x] R1.2 (BLOCKER) home/modules/agents/skills/flow/resume.md:23 - Resume runs
  `tatr show` in main before locating the feature worktree. Reproduced here:
  main reported PLANNED while the feature task reported REVIEWING. Locate the
  worktree first and make its task/context authoritative for active phases.
  - Response: Fixed in this commit. Resume now finds the changed task copy
    before running rooted `tatr show` and `context` commands.
- [x] R1.3 (MAJOR) tasks/20260801-155024/TASK.md:42 - Two DoD proofs do not
  cover their named conjuncts. The stop-path grep also matches the approve
  path, and the terminal proof never inspects landing.md or lessons/SKILL.md.
  Make each command clause/file scoped and verify it fails under sabotage.
  - Response: Fixed in this commit. Proofs now scope the stop path, pin the
    transition commit and rooted resume, and inspect landing and lessons.

- Pending manual: forward-test the four minimal gate/phase states.
- Verified: all three current behavior commands, skill conformance, task and
  ledger checks, sprout integration tests, bare `nix flake check`, and
  `git diff --check` pass.

## Round 2

- REVIEWER: out-of-context
- VERDICT: APPROVE

- Confirmed R1.1: gate transitions are committed before the context cut.
- Confirmed R1.2: resume selects changed worktree state before rooted context.
- Confirmed R1.3: scoped proofs fail under their recorded sabotages.
- Pending manual: forward-test the four minimal gate/phase states.
- Verified: all DoD `cmd:` proofs, sabotage checks, skill conformance, task and
  ledger checks, sprout integration tests, bare `nix flake check`, and
  `git diff --check` pass.
