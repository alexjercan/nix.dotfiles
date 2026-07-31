# Plan simple reviewable one-context changes

- STATUS: OPEN
- PRIORITY: 90
- TAGS: skills,plan,docs,flow
- KIND: STORY
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT
- PARENT: 20260731-174333
- DEPENDS ON: 20260731-142000

## Story

As a planner, I want each Story shaped for the new simplicity review bar and
one cold execution context, so avoidable complexity and oversized diffs are
prevented before work begins.

## Steps

- [ ] Update `home/modules/agents/skills/plan/SKILL.md` and the narrowest
      applicable plan reference with a from-scratch design challenge: choose
      the simplest route that meets the DoD before writing Steps.
- [ ] Add a concept budget. Every proposed mode, branch, option, wrapper,
      extension point, or abstraction needs a named requirement, caller, or
      invariant in this Story; otherwise delete or defer it.
- [ ] Add a reviewability/context budget. Estimate affected ownership
      boundaries and split independently implementable, committable vertical
      slices that can each fit one understand-build-review context.
- [ ] For a large cohesive Story that cannot split without temporary shims or
      broken intermediate behavior, record that reason and its expected breadth
      rather than forcing an artificial task boundary.
- [ ] Keep file/line counts as prompts for inspection, never universal design
      verdicts. Preserve the one-request-one-task rule for genuinely cohesive
      work.
- [ ] Run the skill gate, task/ledger checks, and full flake checks.

## Definition of Done

- Plan explicitly asks whether the route would be chosen from scratch and
  budgets both concepts and reviewable context (cmd: `rg -q 'from scratch' home/modules/agents/skills/plan && rg -q 'concept budget' home/modules/agents/skills/plan && rg -q 'reviewab.*context|context.*reviewab' home/modules/agents/skills/plan`).
- Splitting guidance requires independently landable boundaries and records why
  a broad cohesive Story cannot split cleanly (manual: plan one broad fixture
  request and confirm the result creates landable Stories or names the concrete
  shim/broken-intermediate-state cost that prevents the split).
- The skill suite remains conformant and within all measured budgets (cmd:
  `rg -q 'concept budget' home/modules/agents/skills/plan && bash home/modules/agents/skills/check.sh`).
- Repository checks pass (cmd: `rg -q 'concept budget' home/modules/agents/skills/plan && tatr check && tatr check --ledger LESSONS.md && nix flake check`).

## Notes

- `review/SKILL.md` and `review/dimensions.md` after 20260731-142000 define the
  approval bar this planner must anticipate without duplicating its full prose.
- A huge diff is evidence to question the plan, not proof that the feature was
  divisible. Splits must remain independently useful and green.
