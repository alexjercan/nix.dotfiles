# Harden flow planning and resume gates

- STATUS: OPEN
- PRIORITY: 85
- TAGS: feature,skills,flow

## Flow State

- FLOW STEP: PLANNING

## Story

As the flow user, I want the flow-family skills and tatr checker to prevent
agents from starting work from unconfirmed, duplicate, or merely
checkbox-shaped task records, so a single requested thing stays in one task
unless I explicitly ask for an epic or sprint split.

## Steps

- [ ] Update `flow/SKILL.md` so normal single-goal flow creates or reuses one
      task only. Do not create an umbrella task unless the user explicitly asks
      for an epic, sprint, version, release, or multi-feature goal that needs
      child tasks.
- [ ] Update `flow/SKILL.md` to support existing-task entry points. For an
      existing task ID, read that task folder as the source of current context,
      create no extra task unless the user asks for a broader goal, and always
      begin at problem understanding.
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
- [ ] Land the supporting checker task in /home/alex/personal/tatr first, then
      run the nix.dotfiles gates and capture any manual acceptance items before
      review/compound handoff.

## Definition of Done

- Single-goal no-umbrella behavior is documented in flow
  (cmd: `grep -n "umbrella" home/modules/agents/skills/flow/SKILL.md`).
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
- A separate tatr task exists only because /home/alex/personal/tatr is a
  different repository with its own task tracker.
