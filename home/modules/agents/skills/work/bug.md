# Working a bug

Read this when the task is a bug fix. The order is reproduce, then diagnose,
then fix - a fix written before the reproduction is a guess with a diff.

## 1. Reproduce first

The FIRST artifact is a failing test that replicates the reported behavior,
written before any fix. Use the highest-fidelity harness the project has: an
end-to-end or scenario harness that plays the exact reported situation beats a
unit test of the suspected mechanism. The repository's AGENTS.md usually names
its harness.

A rig that models scheduling or clock behavior must mirror the production
entity's scheduling-relevant components - interpolation opt-ins, sync configs.
A clean trace on a non-faithful rig is not evidence.

## 2. Diagnose from the system

With the reproduction red, trace the ACTUAL mechanism: real numbers, real
traces, real logs. Not theory about how the code should behave. Read the
callee, not its name - a misleading function name has cost a silent no-op
walk.

## 3. Fix, and pin at the bug's own boundary

Make the reproduction green. Then pin the bug where it lives: a unit test that
fails under the bug, not only the downstream end-to-end test that surfaced it.
When a refactor changes how an invariant is enforced, re-pin the invariant on
the NEW mechanism rather than massaging the old assertion until it passes.

## 4. Prove the regression test against the bug

A regression test you never watched fail is not a pin. Demonstrate it failing
on the pre-fix behavior and record the failing numbers in TASK.md.

**A/B safety rule: COMMIT the fix before applying any sabotage.** The restore
is `git checkout <file>`, which against an uncommitted tree restores the
BRANCH BASE and destroys the fix. Commit per sabotage, not per task - a
restore has already reverted uncommitted review fixes once.

## 5. A falsification is a real result

A reproduction that CANNOT be made to fail falsifies the report, and that
closes the task honestly:

- convert the rig into a regression that pins the NON-behavior;
- record the exact evidence rig in TASK.md - systems run, command path,
  components - because without it the evidence misleads the next session;
- route the residual observation (the thing the user actually saw) to the
  right task.

Such a cycle still goes through review and retro. Do not force a code change
where the evidence says none is warranted.

## 6. New entry paths surprise their consumers

When the fix adds a new route into an existing state or mode - a new setter of
a state machine, a new entry into "paused" - grep for everything gated on that
state and list what newly runs in the new context. That list is part of the
close-out.
