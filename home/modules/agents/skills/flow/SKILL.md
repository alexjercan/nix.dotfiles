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

1. **Take the goal, pin it on disk.** Restate it in one or two sentences and
   pin down what "done" means - observable behavior, not vibes. If the goal is
   genuinely ambiguous (a real fork that changes what gets built), ask now;
   this is the cheapest moment to be corrected. Also pin the LANDING SCOPE now:
   when the user's ask mentions a branch or sprout, confirm whether flow lands
   each task to the default branch as usual or stops at the branch -
   discovering this at the land step wastes the whole cycle's momentum.

   Then create the **umbrella task**: `tatr new "Goal: <one-line>" -p 0 -t goal`,
   and write `GOAL.md` in its folder following the format block below - the
   goal statement, the observable done-definition, the landing scope, an empty
   Tasks list and an empty Manual acceptance section. GOAL.md is a free-form
   sibling file, not tatr-managed, so its DATE / UMBRELLA TASK / LANDING SCOPE
   header lines are hand-written (tatr only fills STATUS/PRIORITY/TAGS in
   TASK.md). This is the goal
   artifact: it makes an interrupted flow resumable from the files alone and
   gives Finish something concrete to verify against. The umbrella task stays
   OPEN for the whole run and is closed only at Finish. Commit it before
   planning so the pin survives a crash.

2. **Plan, then GATE.** Run the plan skill: read the code, break the goal into
   tatr tasks with Steps checklists, priorities and dependencies. Append the
   planned tasks to the umbrella's `GOAL.md` Tasks list (one unchecked line
   each, in intended order), so the goal artifact holds the live queue.

   Then STOP at the gate. Present the assembled package - the `GOAL.md`
   done-definition and the ordered task list, plus any DECISION.md records the
   planning made (see the plan skill) - and get an explicit "yes, build this"
   from the user before any worktree is cut. This is a HARD gate, not a
   report-and-continue checkpoint: no sprout, no branch, no code exists until
   the user confirms, because the plan is the cheapest place to catch a goal
   that was misunderstood - a whole cycle spent building the wrong thing is the
   expensive one. If the user wants changes, loop back into planning and
   re-present the package. The only carve-out is the same one every skill has:
   a genuinely trivial, single-task goal the user already spelled out in full
   may proceed on their original go-ahead - when in doubt, gate.

3. **Cycle per task.** Pick the highest-priority OPEN task whose dependencies
   are CLOSED (the priority-0 `goal` umbrella is not a work task - skip it
   here; it is closed at Finish), then:

   1. Read the lessons ledger - `LESSONS.md` at the repo root, or wherever
      the lessons skill's search order finds it - and the last few
      `tasks/*/RETRO.md` when more context helps - apply the lessons; this
      is where the compounding pays off. When the ledger is long, read its
      header, the Pending promotions section and any domain-specific section
      fully, then grep the rest for slugs matching the task's area (crate
      names, subsystem words) rather than re-reading every entry each cycle.
   2. Sprout the task's worktree. From the default branch, cut an isolated
      worktree and feature branch for this task with
      `cd "$(sprout new <type>/<short-slug>)"`, so implementation, tests,
      reviews and the TASK.md updates all live on that branch and never touch
      the main checkout. This is the opening move of every task; `/work`
      performs it, but flow names it explicitly because step 5's merge depends
      on the work having happened in a separate worktree.
   3. Run the work skill: implement the Steps, tests and full check suite on
      the branch sprouted in the previous step.
   4. Run the review skill: round 1 from an out-of-context reviewer by
      default (the review skill defines the mechanism and the trivial-diff
      carve-out), findings into REVIEW.md, then alternate work and review
      rounds until the verdict is APPROVE.
   5. On APPROVE, first bring the branch up to date with the default branch,
      then squash-merge it back so the whole task lands as a single commit.
      This mirrors landing a PR: update the branch from its base, re-verify,
      and only then merge.
      1. In the worktree, merge the current default branch into the feature
         branch (`git merge <default>`, where `<default>` is the local default
         branch - flow does not push, so this is not `origin/*`). Resolve any
         conflicts here, on the branch, and commit the merge; this keeps
         conflict resolution off the default branch, where a bad merge is far
         harder to unwind. If the merge surfaces a red test, run
         `git show <default>:<file>` on the failing test FIRST to decide
         whether your change caused it or you inherited it from a parallel
         task - fix an inherited red as merge integration, naming the source
         task, instead of mis-blaming this branch.
      2. Re-run the full check suite on the updated branch (`/work`'s verify
         step). Proceed only when it is green; if the merge broke something,
         fix it on the branch, and if it changed the work materially, send it
         back through `/review` before merging.
      3. Confirm the branch is now up to date:
         `git merge-base --is-ancestor <default> <branch>` must succeed - the
         default branch tip is an ancestor of the branch. Only an up-to-date
         branch may merge back.
      4. Inspect the diff on the BRANCH now - once the landing starts there
         is no pausing to look. Then land with ONE command:

         ```bash
         sprout land <feature> -m "<subject>" -m "<body>"
         ```

         `sprout land` performs the whole landing atomically in a single
         process: it refuses a dirty main checkout, a detached HEAD, running
         from inside the worktree, or a branch that is not up to date with
         the target; squash-merges and commits with the given message
         (rolling the main checkout back to a clean tree on any failure, so
         a parallel session can never sweep up staged leftovers); then
         removes the worktree, deletes the branch and closes its tmux
         session. Write one clean summary of the finished task
         (Conventional-Commit subject plus short body), not the concatenated
         branch messages. Do not push. This leaves the default branch with
         one commit per task.
   6. Run the compound skill: write the retro for this task.
   7. Tick this task in the umbrella `GOAL.md` Tasks list: check its box and
      append a one-line status (landed commit, review rounds, anything
      notable), the way a spike records a Fix. Open `manual:` DoD items do NOT
      block landing - an APPROVEd branch with pending manual checks still
      lands; move those items into the GOAL.md Manual acceptance section so
      they batch for the Finish checkpoint (the single user-acceptance gate),
      rather than stalling each task on a user round-trip. Then report one
      short progress line to the user (task, verdict, rounds, what is next),
      and continue with the next task.

4. **Finish.** When no OPEN tasks remain (the umbrella aside): run the full
   check suite on the default branch one last time, then verify the sum of the
   work against the umbrella `GOAL.md` done-definition item by item - the sum
   of the work actually delivers the goal, not just that every task is CLOSED.
   Present the batched Manual acceptance list from GOAL.md to the user as a
   checkpoint and collect their verdicts. Run the conformance pass -
   `tatr check --ledger <ledger path>` (usually the repo-root `LESSONS.md`) - and
   turn any findings into fixes or new tasks; the artifacts must lint clean
   before the ledger is compiled. Then run the **lessons skill**
   (`/lessons`) to fold any loose scratch the per-task `/compound` retros did
   not capture into the lessons ledger and clear the scratch drawer, so the
   goal leaves a clean, current ledger. Before closing, dispose of every
   residue so the umbrella never closes with silent loose ends: each unmet or
   deferred done-definition item, unresolved review finding, or dropped task is
   either filed as its own prioritized tatr task or written into GOAL.md as
   explicitly deferred with a reason (a `manual:` item the user rejects becomes
   a new task, not a silent omission). Close the umbrella task
   (`tatr edit <umbrella> -s CLOSED`) once the done-definition is met, and
   commit. Finally give a final report - what was built, task by task, key
   lessons from the retros, and anything deliberately left out. Pushing is the
   user's call.

   The umbrella carries NO REVIEW.md or RETRO.md of its own - it is a tracking
   spine, not a worked task, and its GOAL.md IS its record: the Tasks list is
   its history and the final report is its retrospective. The per-task
   REVIEW/RETRO files hold the detail; duplicating them on the umbrella is
   noise. Because of this, a CLOSED `goal` umbrella is exempt from strict
   `tatr check -S`'s `closed-missing-review`/`closed-missing-retro` rules;
   teaching `tatr check` to skip `goal`-tagged tasks is tracked in tatr task
   20260720-220046. Until that lands, run plain `tatr check` (not `-S`) over a
   run that includes an umbrella, or expect the two known umbrella findings.

## The Goal Artifact (GOAL.md)

`GOAL.md` lives in the umbrella task's folder, next to its `TASK.md`, and is
the one file that pins the whole run. It is created at step 1, its Tasks list
grows at plan time and each land, its Manual acceptance section fills as tasks
land, and it is the thing Finish verifies against. It is also the umbrella's
whole record - the umbrella has no REVIEW.md or RETRO.md of its own (see
Finish), so GOAL.md's Tasks history and the final report stand in for them.
Keep the done-definition observable - each item names its proof (`cmd:`,
`test:` or `manual:`), the
same notation the task DoDs use.

```markdown
# Goal: <one-line goal>

- DATE: <YYYYMMDD>
- UMBRELLA TASK: <umbrella-task-id>
- LANDING SCOPE: <squash-merge to <branch>, push or not, any per-repo notes>

## Goal

<a paragraph or two: what this run delivers and why.>

## Done means

<numbered, observable acceptance criteria, each naming its proof
(same test:/cmd:/manual: notation as a task DoD - see the plan skill)>
1. <criterion> (cmd: `<command that proves it>`)
2. <criterion> (manual: <what the user checks at Finish>)

Overall: <the goal-level green bar, e.g. the full check suite passes>.

## Tasks

Updated as tasks land (one line per land, like a spike's Fix record).

- [ ] <task-id> (p<priority>, <repo>) <short title>
- [x] <task-id> (p<priority>, <repo>) <short title>
      landed <commit>; <n> review rounds; <anything notable>

## Decisions (load-bearing, architectural)

Index of the DECISION.md records this goal produced (see the plan skill); each
line points at the task folder holding the full record. A superseded decision
keeps its line and gains the pointer to what replaced it - the index is a map,
not a rewrite of history.

- <task-id> DECISION.md: <one-line decision> (ACCEPTED)
- <task-id> DECISION.md: <one-line decision> (SUPERSEDED by <task-id>)

## Manual acceptance (batched for the user at Finish)

Accumulates `manual:` DoD items as tasks land; presented at Finish.

- (pending) <task-id>: <what the user should confirm>
```

## Task Playbooks

How a task is tackled depends on what kind of task it is; the cycle is the
same, the emphasis differs.

**Bugs: reproduce first, then research, then fix.** The first deliverable of
a bug task is a failing test that replicates the reported behavior - written
BEFORE any fix, so the diagnosis is aimed rather than guessed. Prefer the
highest-fidelity harness the project has (an end-to-end or scenario-driving
harness that plays the exact reported situation beats a unit test of the
suspected mechanism; the project's AGENTS.md usually names its harness).
With the reproduction red, trace the actual mechanism (real numbers, real
traces - not theory), fix it, and let the same test go green as the
regression pin. A reproduction that CANNOT be made to fail is a result too:
it falsifies the report - convert the rig into a pin of the non-behavior and
close with the evidence.

**Features: spike when fuzzy, then plan, build test-first, verify end to end.**
If the direction is undefined, `/spike` first; then `/plan` into tasks with
Steps and a Definition of Done; then `/work` each task test-FIRST - for every
DoD item with a `test:` or `cmd:` proof, write that check and watch it fail for
the right reason before the implementation, then make it pass (red -> green ->
refactor). Prefer the example/integration altitude for that first test - a
small runnable example or harness-level test that drives the feature the way a
user would, isolated to the one system under test (in a game, the small visual
example that exercises just this mechanism) - dropping to a unit test only when
the seam is genuinely unit-shaped. Then `/review` until APPROVE and
`/compound`. A feature without a harness/example test has only proven its
pieces, not itself; a test written after the code that never failed has proven
nothing.

## When to Stop and Ask

Flow is autonomous between checkpoints, but it stops and surfaces to the user
instead of grinding when:

- the plan turns out wrong enough that the task list needs restructuring, not
  just a new task appended;
- seeded tasks turn out architecturally inseparable (splitting them would
  mean throwaway shim code) - surface the re-cut and merge them into one
  cycle rather than grinding out shims;
- a review dispute survives three rounds (per the review skill);
- the same task fails work-review twice in a row with no clear path forward;
- the goal itself turns out to mean something different than assumed;
- anything destructive or outward-facing comes up (push, deploy, data).

## Guidelines

- Honest phases beat fast phases. Do not soften reviews or skip retros to
  make the loop converge; the cycle only compounds if each phase does its
  real job.
- New work discovered mid-flow becomes a new tatr task and joins the queue in
  priority order; it does not widen the current worktree/branch. Create such
  tasks inside the current worktree (or carry-and-clean a main-checkout stub
  in as the next task's first act) so the file is born on a branch.
- A lesson written mid-flow applies BACKWARD too: re-audit the remaining
  queued tasks and plans against it (re-run the sweeps it invalidates)
  instead of only applying it forward - a poisoned plan sitting in the queue
  is not fixed by the ledger entry alone.
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
- Keep the trail on disk: the umbrella `GOAL.md`, tasks, reviews and retros
  must be committed as the skills prescribe, so a flow interrupted at any
  point can be resumed by a fresh session from the files alone - GOAL.md holds
  the goal, done-definition and live task queue; the rest holds the per-task
  state. That trail is append-only history: once written, a task record is not
  rewritten to match a later rename or refactor - the doc-surface sweep and
  absence-proving DoD greps EXCLUDE the `tasks/` tree and fix only the live doc
  surfaces (work skill, sweep step; plan skill, DoD greps). History stays
  verbatim.

## Relationship to the Other Skills

Flow adds no new mechanics; it is the loop around them. tatr tracks, `/spike`
explores when the goal is still fuzzy, `/plan` scopes, sprout isolates each
task in its own worktree, `/work` implements, `/review` critiques, `/compound`
distills the per-task retro, and `/lessons` (at Finish) folds any loose scratch
into the ledger and clears the scratch drawer - flow just keeps the wheel
turning until the goal is done. Spike is
the optional pre-step: when the goal handed to flow is undefined, spike it
first, then start the flow from its SPIKE.md and the direction-level
tasks it seeded (flow's own `/plan` phase breaks those into steps). Two things
flow does that the individual skills do not: it holds a HARD gate after
planning - the whole task list plus GOAL.md done-definition go to the user for
an explicit "build this" before any worktree is cut (step 2), so a
misunderstood goal is caught while only the plan exists; and every task in the
cycle starts by sprouting a worktree and ends back on the default branch, with
flow landing the APPROVEd branch PR-style - update it from the default branch
first, then, once it is up to date, `sprout land` it (one squash commit on the
default branch, worktree and branch removed) - because the next task needs to
build on it.
