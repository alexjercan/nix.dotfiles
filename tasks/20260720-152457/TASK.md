# DoD items name their proof (test/cmd/manual) across plan, work, review, flow

- STATUS: IN_PROGRESS
- PRIORITY: 85
- TAGS: feature, skills

## Story

As the plan-work-review contract, I want every Definition of Done item to
name its proof (test, command, or manual check), so unverifiable acceptance
criteria are visible at plan time instead of shipping proxy-verified.
Evidence: bevy-common-systems' 12_bastion landed two dead controls behind a
green harness; the ledger patched it as `verify-observable-effect` (x6) when
it is a template fix.

## Steps

- [x] plan SKILL.md: DoD format - each item ends with its proof:
      `(test: <name>)`, `(cmd: <command>)`, or `(manual: <what the user
      confirms>)`; an item with no nameable proof gets rephrased or demoted
      to Notes. Update the example task file to use proofs.
- [x] work SKILL.md verify step: run each `test:`/`cmd:` proof explicitly;
      `manual:` items are reported as pending user confirmation, never
      self-ticked.
- [x] review SKILL.md: the reviewer executes the `test:`/`cmd:` proofs and
      lists open `manual:` items next to the verdict.
- [x] flow SKILL.md: `manual:` items do not block landing; they accumulate on
      the umbrella GOAL.md's Manual acceptance section and are presented as
      a batch at Finish (the user-acceptance gate).
- [x] tatr SKILL.md task-format section: mirror the proof notation.

## Definition of Done

- plan/work/review/flow/tatr skills each carry the proof notation and their
  role in it (cmd: `grep -rn "manual:" home/modules/agents/skills/{plan,work,review,flow,tatr}/SKILL.md`)
- plan SKILL.md's example DoD uses proofs (cmd: `grep -n "cmd:" home/modules/agents/skills/plan/SKILL.md`)
- manual: user confirms the notation reads well in this flow's own task
  files (all plans in this flow already use it)

## Notes

- Depends on: 20260720-152451 (Manual acceptance section lives on GOAL.md).
