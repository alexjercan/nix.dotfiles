# Review: Add the spike skill for ideation and research

- TASK: 20260704-130605
- BRANCH: spike-skill

## Round 1

- VERDICT: REQUEST_CHANGES

- [x] R1.1 (MAJOR) home/modules/agents/skills/spike/SKILL.md:47-49,95-96,121 -
  the spike/plan boundary is self-contradictory. Step 5 has spike create the
  tatr tasks with `tatr new`, and the Doc Format "Next steps" example shows
  fully implementable, plan-grade tasks; but the Relationship section says
  "its seeded tasks are planned and built", implying a `/plan` pass runs
  after. A reader cannot tell whether spike-seeded tasks are already
  implementable (skip plan) or coarse stubs plan must expand, and running
  `/plan` after would duplicate tasks. Pick one model and state it. Chosen
  fix: spike seeds coarse, direction-level tasks (Goal + spike link + `spike`
  tag, no detailed Steps); `/plan` later breaks each into Steps when it is
  picked up. This matches tatr's existing note that a stepless ad-hoc task is
  planned first with `/plan`, and keeps spike about the what/why, plan about
  the how. Make the `:95-96` example coarse to match, and reword `:121` to
  "planned into steps and built".
  - Response: Fixed with the coarse-task model. Step 5 now says spike seeds
    coarse, direction-level tasks (Goal + `Spike:` link + `spike` tag, no
    Steps) and that `/plan` breaks them into Steps later, citing tatr's
    existing stepless-task rule (confirmed at tatr/SKILL.md:70-71). The Doc
    Format "Next steps" example is now coarse, and the Relationship line reads
    "seeded direction-level tasks are planned into steps and built".
- [ ] R1.2 (MINOR) home/modules/agents/skills/flow/SKILL.md - flow still
  describes only plan-work-review-compound and never mentions spike, so
  spike's "front of the funnel / `/flow` drives the whole loop" claim is
  one-directional. Suggested: add a one-line note to flow (and plan, tatr) so
  the lifecycle claim is real from both sides.
  - Response: Out of this task's scope by design - the plan/flow/tatr
    cross-referencing is already tracked as task 20260704-130606, which does
    exactly this. Deferred there rather than widening this branch. Non-blocking
    (MINOR, cross-file).
- [x] R1.3 (NIT) home/modules/agents/skills/spike/SKILL.md:3 - description is
  ~552 chars vs plan 419 / compound 432; trim the trailing clause that
  restates the body.
  - Response: Trimmed the trailing restating clause and the "prototype-think"
    coinage; now 504 chars. Still a touch longer than the siblings, but the
    remaining length is the trigger phrasing a novel skill needs.

## Round 2

- VERDICT: APPROVE

- R1.1 verified resolved: Step 5 now scopes spike to coarse direction-level
  tasks and hands Step-breakdown to `/plan`; the Doc Format example and the
  Relationship sentence are consistent with that single model. The spike/plan
  boundary is no longer contradictory.
- R1.3 verified resolved: description trimmed to 504 chars.
- R1.2 left open by design: it is task 20260704-130606's scope (cross-
  reference spike into plan/flow/tatr), a MINOR that does not block this
  branch. It will be closed there.

No new findings. The diff delivers the Goal.
