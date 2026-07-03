---
name: flow
description: Run the full development cycle end to end for a goal - plan it into tatr tasks, then for each task implement, review until approved, and retro, repeating until the goal is done. Use this skill when the user asks to run a goal with `/flow`, or wants a feature delivered autonomously through the whole plan-work-review-compound loop rather than stepping through the skills by hand.
---

# Flow - Drive a Goal Through the Whole Cycle

Flow is the orchestrator: it takes one goal and runs the other skills in
order - `/plan` once, then `/work`, `/review` and `/compound` per task -
until every planned task is CLOSED and the goal is delivered. The user states
the destination; flow drives.

Each phase follows its own skill exactly. This file only defines the order,
the handoffs, and when to stop and ask the user.

## Workflow

1. **Take the goal.** Restate it in one or two sentences and pin down what
   "done" means - observable behavior, not vibes. If the goal is genuinely
   ambiguous (a real fork that changes what gets built), ask now; this is the
   cheapest moment to be corrected.

2. **Plan.** Run the plan skill: read the code, break the goal into tatr
   tasks with Steps checklists, priorities and dependencies. Report the task
   list to the user before starting to build, as a checkpoint.

3. **Cycle per task.** Pick the highest-priority OPEN task whose dependencies
   are CLOSED, then:

   1. Read the most recent retros in `docs/retros/` - apply the lessons; this
      is where the compounding pays off.
   2. Run the work skill: feature branch, implement the Steps, tests, full
      check suite.
   3. Run the review skill: critique into REVIEW.md, then alternate work and
      review rounds until the verdict is APPROVE.
   4. On APPROVE, merge the feature branch into the default branch locally
      (do not push) so the next task builds on finished work, and delete the
      branch.
   5. Run the compound skill: write the retro for this task.
   6. Report one short progress line to the user (task, verdict, rounds,
      what is next), then continue with the next task.

4. **Finish.** When no OPEN tasks remain: run the full check suite on the
   default branch one last time, verify the sum of the work actually delivers
   the goal from step 1 (not just that every task is CLOSED), and give a
   final report - what was built, task by task, key lessons from the retros,
   and anything deliberately left out. Pushing is the user's call.

## When to Stop and Ask

Flow is autonomous between checkpoints, but it stops and surfaces to the user
instead of grinding when:

- the plan turns out wrong enough that the task list needs restructuring, not
  just a new task appended;
- a review dispute survives three rounds (per the review skill);
- the same task fails work-review twice in a row with no clear path forward;
- the goal itself turns out to mean something different than assumed;
- anything destructive or outward-facing comes up (push, deploy, data).

## Guidelines

- Honest phases beat fast phases. Do not soften reviews or skip retros to
  make the loop converge; the cycle only compounds if each phase does its
  real job.
- New work discovered mid-flow becomes a new tatr task and joins the queue in
  priority order; it does not widen the current branch.
- One flow, one goal. A second goal gets its own `/flow` run.
- Keep the trail on disk: tasks, reviews and retros must be committed as the
  skills prescribe, so a flow interrupted at any point can be resumed by a
  fresh session from the files alone.

## Relationship to the Other Skills

Flow adds no new mechanics; it is the loop around them. tatr tracks, `/plan`
scopes, `/work` implements, `/review` critiques, `/compound` distills - flow
just keeps the wheel turning until the goal is done. The one thing flow does
that the individual skills do not: merge an APPROVEd branch into the default
branch, because the next task needs to build on it.
