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
   5. On APPROVE, first bring the branch up to date with the default branch,
      then squash-merge it back so the whole task lands as a single commit.
      This mirrors landing a PR: update the branch from its base, re-verify,
      and only then merge.
      1. In the worktree, merge the current default branch into the feature
         branch (`git merge <default>`, where `<default>` is the local default
         branch - flow does not push, so this is not `origin/*`). Resolve any
         conflicts here, on the branch, and commit the merge; this keeps
         conflict resolution off the default branch, where a bad merge is far
         harder to unwind.
      2. Re-run the full check suite on the updated branch (`/work`'s verify
         step). Proceed only when it is green; if the merge broke something,
         fix it on the branch, and if it changed the work materially, send it
         back through `/review` before merging.
      3. Confirm the branch is now up to date:
         `git merge-base --is-ancestor <default> <branch>` must succeed - the
         default branch tip is an ancestor of the branch. Only an up-to-date
         branch may merge back.
      4. Land from the main checkout - it has stayed on the default branch
         the whole time (the work happened in a separate worktree), and you
         cannot remove a worktree while standing inside it. The landing is
         its OWN command that contains no `cd` at all and starts with
         `pwd` to prove where it runs - this rule exists because the
         squash keeps getting appended to compound commands that cd'd
         into the worktree, where it silently no-ops or merges a branch
         into itself (three retros and counting). Then run
         `git merge --squash <branch>`, which stages the branch's changes
         without committing. Because the branch already contains the default
         tip, this applies cleanly with no conflicts on the default branch.
         Then `git commit` with a message that summarizes the finished task as
         a whole (a Conventional-Commit subject plus a short body); git
         pre-fills the concatenated branch commit messages, so replace them
         with one clean summary rather than shipping the intermediate steps.
         Do not push. This leaves the default branch with one commit per task
         instead of the branch's individual commits and a merge bubble, while
         the next task still builds on finished work.
      5. Finally `sprout rm <feature>` to remove the worktree, delete the
         branch, and close its tmux session (`--squash` records no merge
         parent, but `sprout rm` force-deletes the branch, so this is fine).
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
- User feedback arriving mid-cycle follows the same discipline: finish the
  cycle in flight first, then file each REQUEST as its own prioritized
  task, and record each VERDICT ("X feels fixed", "Y still happens") as a
  dated interim note on the relevant open task or umbrella - playtest
  confirmations are evidence, and losing them costs a re-test.
- A cycle may legitimately end in a falsification instead of a fix: the
  investigation proves the reported mechanism does not exist, closes the
  task with the evidence rig recorded and a regression pinning the
  non-behavior, and routes the residual observation to the right task.
  Such a cycle still goes through review and retro - do not force a code
  change where the evidence says none is warranted.
- One flow, one goal. A second goal gets its own `/flow` run.
- Keep the trail on disk: tasks, reviews and retros must be committed as the
  skills prescribe, so a flow interrupted at any point can be resumed by a
  fresh session from the files alone.

## Relationship to the Other Skills

Flow adds no new mechanics; it is the loop around them. tatr tracks, `/spike`
explores when the goal is still fuzzy, `/plan` scopes, sprout isolates each
task in its own worktree, `/work` implements, `/review` critiques, `/compound`
distills - flow just keeps the wheel turning until the goal is done. Spike is
the optional pre-step: when the goal handed to flow is undefined, spike it
first, then start the flow from the `docs/spikes/` doc and the direction-level
tasks it seeded (flow's own `/plan` phase breaks those into steps). Every task
in the cycle starts by sprouting a worktree and ends back on the default
branch; the one thing flow does that the individual skills do not is land an
APPROVEd branch PR-style - update it from the default branch first, then, once
it is up to date, squash-merge it into the default branch as a single commit
(and `sprout rm` its worktree) - because the next task needs to build on it.
