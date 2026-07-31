# Turn review and context overruns into planning lessons

- STATUS: OPEN
- PRIORITY: 75
- TAGS: skills,compound,lessons,docs,flow
- KIND: STORY
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT
- PARENT: 20260731-174333
- DEPENDS ON: 20260731-142000, 20260731-174348

## Story

As a compound agent, I want reviews and worker checkpoints mined for planning
failures, so oversized diffs, structural rework, and context overruns improve
the next plan instead of ending as isolated implementation pain.

## Steps

- [ ] Update `home/modules/agents/skills/compound/SKILL.md` to compare the
      original Story/Steps with the final diff, branch log, all review rounds,
      `Process signal:` observations, and recorded worker checkpoints.
- [ ] For unexpected breadth, ask why the diff grew: inherently large feature,
      missed independently landable split, weak ownership boundary, scope
      discovered late, or a plan that encoded the wrong design.
- [ ] For structural review churn, identify which from-scratch or cold-reader
      question at plan time would have prevented the rework. Name the failed
      decision and why it seemed sound then; do not blame the worker.
- [ ] For context pressure, record only measured or explicitly observed facts:
      threshold crossing, compaction warning, handoff, delegation, and what
      should be split, delegated, deferred, or loaded later next time. Never
      invent token counts absent from task records.
- [ ] Keep code findings in REVIEW, change facts in TASK, one-off process detail
      in RETRO, and only recurring general lessons in LESSONS.md.
- [ ] Preserve the compound body budget, ledger ownership, and landing order.
      Run all canonical checks.

## Definition of Done

- Compound explicitly asks why the diff grew, whether a split was missed, and
  how the plan caused structural review churn (cmd: `rg -q 'why the diff grew' home/modules/agents/skills/compound && rg -q 'missed.*split|split.*missed' home/modules/agents/skills/compound && rg -q 'plan.*review|review.*plan' home/modules/agents/skills/compound`).
- Compound audits context-budget evidence without inventing unavailable token
  counts (cmd: `rg -q 'context' home/modules/agents/skills/compound && rg -q 'token' home/modules/agents/skills/compound && rg -q 'invent|recorded' home/modules/agents/skills/compound`).
- Record ownership remains unambiguous (manual: fresh reviewer confirms REVIEW
  owns findings, TASK owns change facts, RETRO owns one-off process analysis,
  and LESSONS owns recurring general lessons).
- The skill suite remains conformant and within all measured budgets (cmd:
  `rg -q 'why the diff grew' home/modules/agents/skills/compound && bash home/modules/agents/skills/check.sh`).
- Repository checks pass (cmd: `rg -q 'why the diff grew' home/modules/agents/skills/compound && tatr check && tatr check --ledger LESSONS.md && nix flake check`).

## Notes

- Depends on the review task for `Process signal:` format and the work task for
  durable checkpoint evidence.
- Large PRs are red flags to diagnose, not automatic proof of a bad plan. The
  retro must distinguish indivisible feature size from avoidable task breadth.
