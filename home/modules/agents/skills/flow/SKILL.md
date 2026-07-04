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
   2. Sprout the task's worktree. From the default branch, cut an isolated
      worktree and feature branch for this task with
      `cd "$(sprout new <type>/<short-slug>)"`, so implementation, tests,
      reviews and the TASK.md updates all live on that branch and never touch
      the main checkout. This is the opening move of every task; `/work`
      performs it, but flow names it explicitly because step 5's merge depends
      on the work having happened in a separate worktree.
   3. Run the work skill: implement the Steps, tests and full check suite on
      the branch sprouted in the previous step.
   4. Run the review skill: critique into REVIEW.md, then alternate work and
      review rounds until the verdict is APPROVE.
   5. On APPROVE, squash-merge the feature branch into the default branch
      locally, so the whole task lands as a single commit. The main checkout
      has stayed on the default branch the whole time (the work happened in a
      separate worktree), so `cd` back to it - you cannot remove a worktree
      while standing inside it - and run `git merge --squash <branch>`, which
      stages the branch's changes without committing. Then `git commit` with a
      message that summarizes the finished task as a whole (a
      Conventional-Commit subject plus a short body); git pre-fills the
      concatenated branch commit messages, so replace them with one clean
      summary rather than shipping the intermediate steps. Do not push. This
      leaves the default branch with one commit per task instead of the
      branch's individual commits and a merge bubble, while the next task still
      builds on finished work. Finally `sprout rm <feature>` to remove the
      worktree, delete the branch, and close its tmux session (`--squash`
      records no merge parent, but `sprout rm` force-deletes the branch, so
      this is fine).
   6. Run the compound skill: write the retro for this task.
   7. Report one short progress line to the user (task, verdict, rounds,
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
  priority order; it does not widen the current worktree/branch.
- One flow, one goal. A second goal gets its own `/flow` run.
- Keep the trail on disk: tasks, reviews and retros must be committed as the
  skills prescribe, so a flow interrupted at any point can be resumed by a
  fresh session from the files alone.

## Relationship to the Other Skills

Flow adds no new mechanics; it is the loop around them. tatr tracks, `/plan`
scopes, sprout isolates each task in its own worktree, `/work` implements,
`/review` critiques, `/compound` distills - flow just keeps the wheel turning
until the goal is done. Every task in the cycle starts by sprouting a
worktree and ends back on the default branch; the one thing flow does that the
individual skills do not is squash-merge an APPROVEd branch into the default
branch as a single commit (then `sprout rm` its worktree), because the next
task needs to build on it.
