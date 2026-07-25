# Update flow skills for planned-state gates

- STATUS: OPEN
- PRIORITY: 85
- TAGS: feature,skills,flow

## Story

As the flow user, I want the local flow-family skills to treat understanding,
planning, work, review, and retro as explicit durable phases, so `flow task
<id>` resumes the named task safely and `/work` cannot start from a checklist
that was never confirmed as the real plan.

## Steps

- [ ] Update `flow/SKILL.md` to support both new-goal and existing-task entry
      points. For an existing task ID, read that task folder as the source of
      current context, create no extra umbrella task unless the user asks for a
      broader goal, and always begin at problem understanding.
- [ ] Add an understanding gate to `flow/SKILL.md` and `plan/SKILL.md`: compare
      the user request, task text, and artifacts; ask questions or state
      explicit assumptions when any part is incomplete, stale, contradictory,
      or potentially wrong; do not plan until the implementation intent is
      confirmed.
- [ ] Define the durable task marker contract in the skills:
      `## Flow State`,
      `- FLOW STEP: UNDERSTANDING|PLANNING|PLANNED|WORKING|REVIEWING|COMPOUNDING|DONE`,
      and `- PLAN STATUS: APPROVED` after the user accepts the plan.
- [ ] Teach `flow/SKILL.md` to update the task marker at phase transitions and
      to write `PLAN STATUS: APPROVED` only after the plan gate receives an
      explicit user approval.
- [ ] Update `work/SKILL.md` so it refuses implementation for a task that lacks
      `PLAN STATUS: APPROVED` or the full planning artifacts, and removes the
      old behavior where a `## Steps` checklist by itself could authorize work.
- [ ] Update `tatr/SKILL.md` and any directly related skill docs to describe
      the new checker rule from /home/alex/personal/tatr and the exact marker
      spelling.
- [ ] Run the repo gates and capture any manual acceptance items in the goal
      record before the review/compound handoff.

## Definition of Done

- Existing-task mode is documented in flow
  (cmd: `grep -n "existing task" home/modules/agents/skills/flow/SKILL.md`).
- Understanding-before-plan is documented in flow and plan
  (cmd: `grep -rn "understanding" home/modules/agents/skills/{flow,plan}/SKILL.md`).
- The durable marker contract is documented across relevant skills
  (cmd: `grep -rn "FLOW STEP" home/modules/agents/skills/{flow,plan,work,tatr}/SKILL.md`).
- Work refusal for unplanned tasks is documented
  (cmd: `grep -n "PLAN STATUS: APPROVED" home/modules/agents/skills/work/SKILL.md`).
- nix.dotfiles tatr gates pass
  (cmd: `/home/alex/personal/tatr/tatr check` and
  `/home/alex/personal/tatr/tatr check --ledger LESSONS.md`).
- nix.dotfiles flake evaluates
  (cmd: `nix flake check --no-build`).

## Dependencies

- Requires tatr checker task `20260725-111031` to land first so the skill docs
  describe the real CLI behavior rather than aspirational lint.

## Notes

- This task is about the deployed skill source in
  `home/modules/agents/skills/`, not the copied runtime skill files under the
  home directory.
- Preserve the rule that unchecked `## Steps` lines are implementation steps
  only after planning is approved. They are not proof that the user accepted
  the task as planned.
- The local skill family being updated is `flow`, `plan`, `work`, and `tatr`;
  touch `review`, `compound`, or `lessons` only if a direct reference would
  become stale.
