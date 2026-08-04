# Harden flow planning and resume gates

- PRIORITY: 85
- TAGS: feature, skills, flow
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE

## Story

As the flow user, I want the flow-family skills and tatr checker to prevent
agents from starting work from unconfirmed, duplicate, or merely
checkbox-shaped task records, so a single requested thing stays in one task
unless I explicitly ask for an epic or sprint split.

## Steps

- [x] Update `flow/SKILL.md` so normal single-goal flow creates or reuses one
      task only. Do not create an umbrella task unless the user explicitly asks
      for an epic, sprint, version, release, or multi-feature goal that needs
      child tasks.
- [x] Update `flow/SKILL.md` to support existing-task entry points. For an
      existing task ID, read that task folder as the source of current context,
      create no extra task unless the user asks for a broader goal, and always
      begin at problem understanding.
- [x] Add an understanding gate to `flow/SKILL.md` and `plan/SKILL.md`: compare
      the user request, task text, and artifacts; ask questions or state
      explicit assumptions when any part is incomplete, stale, contradictory,
      or potentially wrong; do not plan until the implementation intent is
      confirmed.
- [x] Define the durable task marker contract in the skills:
      `## Flow State`,
      `- FLOW STEP: UNDERSTANDING|PLANNING|PLANNED|WORKING|REVIEWING|COMPOUNDING|DONE`,
      and `- PLAN STATUS: APPROVED` after the user accepts the plan.
- [x] Teach `flow/SKILL.md` to update the task marker at phase transitions and
      to write `PLAN STATUS: APPROVED` only after the plan gate receives an
      explicit user approval.
- [x] Update `work/SKILL.md` so it refuses implementation for a task that lacks
      `PLAN STATUS: APPROVED` or the full planning artifacts, and removes the
      old behavior where a `## Steps` checklist by itself could authorize work.
- [x] Update `tatr/SKILL.md` and any directly related skill docs to describe
      the new checker rule from /home/alex/personal/tatr and the exact marker
      spelling.
- [x] Land the supporting checker task in /home/alex/personal/tatr first, then
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

## Work Notes

- Landed the supporting tatr checker change first:
  `/home/alex/personal/tatr` commit `e977b33 feat(check): require approved flow plans`.
- Rewrote `flow/SKILL.md` so one requested thing maps to one active tatr task by
  default. Umbrella/container tasks and `GOAL.md` now exist only for explicit
  epic, sprint, version, release, or multi-feature requests.
- Added existing-task flow rules: `flow task <id>` reads the named task folder
  and siblings as context, starts from problem understanding, and does not
  create a duplicate task.
- Added the durable `## Flow State` marker contract and phase transitions:
  UNDERSTANDING, PLANNING, PLANNED, WORKING, REVIEWING, COMPOUNDING, DONE.
- Updated `plan/SKILL.md` so planning begins with problem understanding and
  updates existing tasks instead of duplicating them.
- Updated `work/SKILL.md` so it refuses unplanned tasks. A `## Steps` checklist
  without `PLAN STATUS: APPROVED` no longer authorizes implementation.
- Updated `tatr/SKILL.md` with `bad-flow-state`, `unplanned-in-progress`, and
  the exact marker spelling from the landed tatr checker.

## Verification

- `grep -n "umbrella" home/modules/agents/skills/flow/SKILL.md` passed.
- `grep -n "existing task" home/modules/agents/skills/flow/SKILL.md` passed.
- `grep -rn "understanding" home/modules/agents/skills/{flow,plan}/SKILL.md`
  passed.
- `grep -rn "FLOW STEP" home/modules/agents/skills/{flow,plan,work,tatr}/SKILL.md`
  passed.
- `grep -n "PLAN STATUS: APPROVED" home/modules/agents/skills/work/SKILL.md`
  passed.
- `/home/alex/personal/tatr/tatr check` passed silently.
- `/home/alex/personal/tatr/tatr check --ledger LESSONS.md` passed silently.
- `nix flake check --no-build` passed.
- `bash home/modules/scripts/sprout-test.sh` passed 14/14.
- Stale surface sweep for old umbrella-first wording found only intended
  "do not create umbrella" and explicit epic-template references.

## Reflection

- What went well: landing the tatr checker first made the skill docs describe
  real CLI behavior instead of aspirational process prose.
- What went wrong: the initial plan created exactly the extra single-goal child
  task this change is meant to prevent. The task was folded back before
  implementation, and the final skill text now forbids that default.
- Next time: apply the new "one requested thing, one task" rule while planning
  the flow itself, not only as a target behavior for future sessions.
