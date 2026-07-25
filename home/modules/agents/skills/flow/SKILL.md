---
name: flow
description: Run the full development cycle end to end for a goal - understand it, plan the active tatr task, gate for user approval, then implement, review until approved, retro, and land. Use this skill when the user asks to run a goal with `/flow`, `flow task <id>`, or wants a feature delivered autonomously through the whole plan-work-review-compound loop rather than stepping through the skills by hand.
---

# Flow - Drive a Goal Through the Whole Cycle

Flow is the orchestrator: it takes one user goal and runs the other skills in
order - understand, `/plan`, `/work`, `/review`, `/compound`, land - until the
planned work is CLOSED and the goal is delivered. The user states the
destination; flow drives.

Default shape: one requested thing is one tatr task. Do not create an umbrella,
epic, sprint, version, release, or child-task structure unless the user
explicitly asks for that broader multi-feature container.

Each phase follows its own skill exactly. This file only defines the order,
the handoffs, and when to stop and ask the user.

## Workflow

1. **Choose the active task shape.** Restate the goal in one or two sentences
   and pin down what "done" means - observable behavior, not vibes. Also pin
   the LANDING SCOPE now: when the user's ask mentions a branch or sprout,
   confirm whether flow lands to the default branch as usual or stops at the
   branch.

   Then choose exactly one of these shapes:

   - Existing task: if the user says `flow task <id>` or names a tatr task ID,
     use `tasks/<id>/TASK.md` as the active task. Read that task and every
     sibling artifact in its folder (`GOAL.md`, `DECISION.md`, `SPIKE.md`,
     `REVIEW.md`, `RETRO.md`, `NOTES.md`) before deciding what is understood.
     Never create another task for the same requested thing.
   - New single task: if the user asks for one cohesive feature, bug, refactor,
     doc change, or investigation and no task exists yet, create one normal
     tatr task for it. Write the problem statement, done definition, Steps and
     Flow State in that same `TASK.md`.
   - Explicit epic: only when the user explicitly asks for a sprint, version,
     release, epic, or multi-feature goal, create a `goal` container plus child
     tasks. In that mode the container may have a `GOAL.md`; otherwise do not
     create one.

2. **Understand before planning.** Start with problem understanding every time,
   even for an existing task. Task text is context, not authority: it may be
   stale, incomplete, manually checklisted, or nonsense. Compare the current
   user request, `TASK.md`, sibling artifacts, relevant code, and backlog. If
   they conflict or leave a real fork in what would be built, ask the user
   before planning. If the answer can be inferred safely from code and local
   conventions, state the assumption explicitly in the task.

   Record the phase in `TASK.md` while doing this work:

   ```markdown
   ## Flow State

   - FLOW STEP: UNDERSTANDING
   ```

   Move to `- FLOW STEP: PLANNING` only once the concrete artifact or behavior
   is understood well enough to plan. Do not skip this step because the task has
   `- [ ]` checkboxes; unchecked Steps alone never prove planning happened.

3. **Plan, then GATE.** Run the plan skill against the active task shape:
   keep a cohesive single-goal change in the active task, and split into child
   tasks only for an explicit epic. The plan must give every work task a
   `## Steps` checklist and `## Definition of Done` proofs.

   Then STOP at the gate. Present the assembled package - the active task's
   done-definition and Steps, or the explicit epic's `GOAL.md` plus child task
   list, plus any DECISION.md records - and get an explicit "yes, build this"
   from the user before any worktree is cut. This is a HARD gate: no sprout, no
   branch, no code exists until the user confirms. If the user wants changes,
   loop back into planning and re-present the package.

   After the user approves, write these markers to every task that may enter
   work:

   ```markdown
   ## Flow State

   - FLOW STEP: PLANNED
   - PLAN STATUS: APPROVED
   ```

   `PLAN STATUS: APPROVED` is the durable proof that the user accepted the
   plan. A task may proceed to work only with that marker, or with a legacy
   task-local planning package such as `GOAL.md` plus `DECISION.md` that
   explicitly records an approved plan. End the gate presentation with
   `PLANNED <task-id>`, using the active task ID for single-task flow or the
   explicit epic container ID for epic flow.

4. **Cycle per work task.** Pick the active work task. For single-task flow,
   that is the active task itself. For explicit epic flow, pick the
   highest-priority OPEN child task whose dependencies are CLOSED and skip the
   `goal` container until Finish. Before sprouting, refuse to work if the task
   lacks `PLAN STATUS: APPROVED` and lacks a legacy task-local planning package
   such as `GOAL.md` plus `DECISION.md`.

   For each work task:

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
      the main checkout. After sprouting, set STATUS to `IN_PROGRESS` and
      `FLOW STEP: WORKING` in that branch. This is the opening move of every
      task; `/work` performs it, but flow names it explicitly because landing
      depends on the work having happened in a separate worktree.
   3. Run the work skill: implement the Steps, tests and full check suite on
      the branch sprouted in the previous step.
   4. Run the review skill: round 1 from an out-of-context reviewer by
      default (the review skill defines the mechanism and the trivial-diff
      carve-out), findings into REVIEW.md, then alternate work and review
      rounds until the verdict is APPROVE.
   5. On APPROVE, set `FLOW STEP: COMPOUNDING` and run the compound skill to
      write the retro for this task NOW, before the land, and commit it on the
      feature branch. Compound already
      commits on the branch when the work is not yet merged, and its done-gate
      is satisfied here: `/work` has set the task CLOSED and `/review` has
      returned APPROVE. Writing the retro before the land is what keeps the
      task to ONE commit: the squash-merge in the next step folds the retro
      into the same commit as the feature, instead of leaving it as a separate
      retro commit on the default branch afterwards.
   6. Bring the branch up to date with the default branch, then squash-merge it
      back so the whole task - implementation, tests, TASK.md close-out and the
      RETRO.md from the previous step - lands as a single commit. This mirrors
      landing a PR: update the branch from its base, re-verify, and only then
      merge.
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
      4. Inspect the diff on the BRANCH now - including the committed RETRO.md -
         once the landing starts there is no pausing to look. Then land with
         ONE command:

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
   7. Set `FLOW STEP: DONE` before landing the approved branch. In explicit
      epic flow, also tick this task in the container `GOAL.md` Tasks list and
      move any `manual:` DoD items into the container's Manual acceptance
      section. In single-task flow, the task's own TASK/REVIEW/RETRO files are
      the record; do not invent a container after the fact. Then report one
      short progress line ending with `DONE <id>` for the task that landed.

5. **Finish.** When the active task is landed, or when no child tasks remain
   for an explicit epic, run the full check suite on the default branch one
   last time. Verify the delivered work against the active task's Definition of
   Done, or against the explicit epic `GOAL.md` if one exists. Run the
   conformance pass - `tatr check --ledger <ledger path>` (usually the
   repo-root `LESSONS.md`) - and turn findings into fixes or new tasks. Run the
   **lessons skill** (`/lessons`) to fold any loose scratch the per-task
   `/compound` retros did not capture into the lessons ledger and clear the
   scratch drawer.

   A single-task flow finishes with `GOAL DONE <task-id>`. An explicit epic
   flow closes the `goal` container only after its done-definition is met, and
   then finishes with `GOAL DONE <container-id>`. Pushing is the user's call.

## Flow State Marker

The active task's `TASK.md` carries the phase state:

```markdown
## Flow State

- FLOW STEP: UNDERSTANDING|PLANNING|PLANNED|WORKING|REVIEWING|COMPOUNDING|DONE
- PLAN STATUS: APPROVED
```

Rules:

- `FLOW STEP` records where flow is right now and should be updated at phase
  transitions.
- `PLAN STATUS: APPROVED` is written only after the user explicitly accepts
  the plan gate.
- `## Steps` checkboxes are not a planning marker. A user or earlier agent can
  write checkboxes before the problem is understood.
- `/work` must refuse an IN_PROGRESS transition when the task lacks
  `PLAN STATUS: APPROVED`, unless it is a legacy task with a task-local
  planning package such as `GOAL.md` plus `DECISION.md` that explicitly records
  approval.
- `tatr check` enforces the mechanical part with `bad-flow-state` and
  `unplanned-in-progress`.

## Explicit Epic Artifact (GOAL.md)

`GOAL.md` exists only for an explicit epic, sprint, version, release, or
multi-feature container. It lives beside the container task's `TASK.md` and
pins the broader done-definition, child task queue, decision index, and batched
manual acceptance items. Do not create `GOAL.md` for a normal single requested
thing.

```markdown
# Goal: <one-line epic>

- DATE: <YYYYMMDD>
- CONTAINER TASK: <task-id>
- LANDING SCOPE: <squash-merge to <branch>, push or not, any per-repo notes>

## Goal

<what this epic delivers and why>

## Done means

1. <criterion> (cmd: `<command that proves it>`)
2. <criterion> (manual: <what the user checks at Finish>)

## Tasks

- [ ] <task-id> (p<priority>, <repo>) <short title>
- [x] <task-id> (p<priority>, <repo>) <short title>
      landed <commit>; <n> review rounds; <anything notable>

## Decisions (load-bearing, architectural)

- <task-id> DECISION.md: <one-line decision> (ACCEPTED)

## Manual acceptance (batched for the user at Finish)

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
- a request underspecifies WHAT to build, not just how - it fixes the
  placement or the LOOK of a thing but not the concrete artifact/mechanism,
  and the plausible shapes are not interchangeable because a constraint makes
  them mutually exclusive. Do not infer a shape and build it. This session's
  miss: "put the objective hint in the top bar" fixed the placement but not
  whether it was a bcs status ITEM - and a bcs status item cannot carry the
  bordered pill the hint had, so "status item" and "keep the pill" could not
  both hold. That incompatibility WAS the decision, and it had to go to the
  user (and into a DECISION.md) before building, not get silently resolved by
  guessing. Even an `AskUserQuestion` does not cover this if it offers options
  without naming the constraint that makes them exclusive - the user then
  picks blind and you build a fourth thing anyway;
- anything destructive or outward-facing comes up (push, deploy, data).

## Guidelines

- Signal each stage's completion with a terminal STATUS LINE the user (and any
  tooling watching the stream) can grep at a glance: the stage name in caps
  followed by the task id, as the LAST line of that phase's report. The
  vocabulary tracks the skills - `SPIKED <id>` (spike done), `PLANNED <id>`
  (plan gate presented), `DONE <id>` (a task lands CLOSED), `GOAL DONE <id>`
  (the whole run finishes at Finish). One id per line. Emit the
  marker only when the stage is GENUINELY complete: a task is `DONE` only after
  it lands on the default branch, never at APPROVE or at CLOSED-but-unlanded -
  the marker means "this phase is behind us", so it must not fire early.
- Honest phases beat fast phases. Do not soften reviews or skip retros to
  make the loop converge; the cycle only compounds if each phase does its
  real job.
- Confirm the concrete ARTIFACT before you build it, then record the choice in
  a DECISION.md - both are mandatory for any load-bearing build-shape fork,
  whether it surfaces at the plan gate or mid-flow. Confirming the goal, the
  placement, or the desired look is NOT enough: name the actual type/mechanism
  you will produce (a bcs status item? a bespoke child node? a new widget?) and
  surface the constraints that make the candidates mutually exclusive, so the
  user decides the real fork instead of you inferring a shape and hitting the
  conflict while coding. When you find mid-build that the confirmed choice
  cannot satisfy every stated want at once (this session: a status item cannot
  have the pill), STOP and re-confirm - do not quietly ship a compromise. The
  confirmed choice is then the DECISION.md; a load-bearing choice built without
  that confirm-then-record step is the exact miss this guideline exists to
  prevent (see the plan skill's DECISION.md section for the record format).
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
  dated interim note on the relevant active task or explicit epic container -
  playtest confirmations are evidence, and losing them costs a re-test.
- A cycle may legitimately end in a falsification instead of a fix: the
  investigation proves the reported mechanism does not exist, closes the
  task with the evidence rig recorded and a regression pinning the
  non-behavior, and routes the residual observation to the right task.
  Such a cycle still goes through review and retro - do not force a code
  change where the evidence says none is warranted.
- One flow, one goal. A second goal gets its own `/flow` run.
- Keep the trail on disk: the active task, its Flow State marker, reviews and
  retros must be committed as the skills prescribe, so a flow interrupted at
  any point can be resumed by a fresh session from the files alone. Only an
  explicit epic has a `GOAL.md`; single-task flow relies on the task's own
  TASK/REVIEW/RETRO records. That trail is append-only history: once written, a
  task record is not rewritten to match a later rename or refactor - the
  doc-surface sweep and absence-proving DoD greps EXCLUDE the `tasks/` tree and
  fix only the live doc surfaces (work skill, sweep step; plan skill, DoD
  greps). History stays verbatim.

## Relationship to the Other Skills

Flow adds little new machinery; it is the loop around the other skills. tatr
tracks, `/spike` explores when the goal is still fuzzy, `/plan` scopes, sprout
isolates each task in its own worktree, `/work` implements, `/review`
critiques, `/compound` distills the per-task retro, and `/lessons` (at Finish)
folds any loose scratch into the ledger and clears the scratch drawer. Spike is
the optional pre-step: when the goal handed to flow is undefined, spike it
first, then start the flow from its SPIKE.md and the direction-level tasks it
seeded.

Flow does three things the individual skills do not: it starts from problem
understanding even when a task already exists; it holds a HARD gate after
planning and writes `PLAN STATUS: APPROVED` only after the user says "yes,
build this"; and it lands each APPROVEd branch PR-style - update it from the
default branch first, then, once it is up to date, `sprout land` it as one
squash commit.
