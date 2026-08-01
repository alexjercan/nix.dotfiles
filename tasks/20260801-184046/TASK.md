# Require one independently sabotageable claim per DoD item

- STATUS: OPEN
- PRIORITY: 60
- TAGS: skills,plan,proofs,lessons,docs
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

As a flow planner, I want each DoD item to contain one independently
sabotageable claim, so a broad proof cannot pass from a neighboring file,
section, or clause.

## Steps

- [ ] Update `home/modules/agents/skills/plan/proofs.md` to require one
      independently sabotageable claim per DoD item and a file/section-scoped
      proof for that claim.
- [ ] Re-read neighboring proof rules in `plan/SKILL.md`, `work/verify.md`, and
      `review/dimensions.md`; remove contradictions or restatements instead of
      adding another owner.
- [ ] Sabotage the new clause against committed HEAD, confirm its proof alone
      turns red, restore exactly, and run every repository gate.

## Definition of Done

- The plan proof contract requires one independently sabotageable claim per
  DoD item and scopes its proof to the owning file or section
  (cmd: `rg -q 'one independently sabotageable claim' home/modules/agents/skills/plan/proofs.md && rg -q 'file/section-scoped' home/modules/agents/skills/plan/proofs.md`).
- Neighboring proof guidance has one owner and no contradictory route
  (manual: fresh reviewer reads plan, work, and review proof guidance together).
- Skill budgets, task records, ledger, and repository checks pass
  (cmd: `bash home/modules/agents/skills/check.sh && tatr check && tatr check --ledger LESSONS.md && nix flake check`).

## Notes

- Promotion target for `proof-must-cover-its-conjunct` (x3, PROMOTE).
- Promotion-order audit: a tool or template cannot safely infer semantic
  conjuncts. Skill prose owns the judgement; the task keeps one rule owner.
- Seeded by review Round 1 of 20260801-155024.
