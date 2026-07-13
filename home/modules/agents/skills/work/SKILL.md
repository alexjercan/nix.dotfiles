---
name: work
description: Implement a planned tatr task end to end in an isolated git worktree (via sprout), with tests and verification. Use this skill when the user asks to start work with `/work`, to implement or pick up a task from the backlog, or to execute a plan created earlier. It takes a tatr task (given by ID or chosen from the backlog), creates a sprout worktree and feature branch, works through the task's steps, and delivers a working, tested solution.
---

# Work - Implement a Tatr Task on a Feature Branch

Work is the step after planning: take one tatr task, implement it to
completion, and leave behind working code, passing tests, and an updated
TASK.md. See the tatr skill for the CLI and file format, and the plan skill
for how tasks get their Steps.

The goal is a solution a serious developer would ship, not the minimum diff
that appears to work.

## Workflow

1. **Pick the task.** If the user named a task ID, use it. Otherwise run
   `tatr ls --sort priority` and pick the highest-priority OPEN task, or ask
   if the choice is genuinely unclear. Read `tasks/<id>/TASK.md` fully,
   including Notes and any `Depends on:` entries; if a dependency task is not
   CLOSED, stop and tell the user instead of building on missing work.

2. **Start the task.** Prefer an isolated worktree over a bare branch, so this
   task never collides with other work in flight. With `HEAD` on the intended
   base (usually the default branch), create the worktree with sprout and move
   into it:

   ```bash
   cd "$(sprout new <type>/<short-slug>)"
   ```

   `sprout new` cuts the branch off the current `HEAD` and checks it out in a
   fresh worktree under the sprouts cache, printing its path. Do all of the
   task's work inside that worktree. Only after you are in it, set STATUS to
   `IN_PROGRESS` in `tasks/<id>/TASK.md` (the tasks/ tree is present on the
   branch, so edits and commits travel with the work and merge back later).
   Derive `<type>` from the task's tags (`feature`, `bug` -> `fix`,
   `refactor`, ...) and `<short-slug>` from the title, e.g.
   `feature/api-rate-limiting`. If sprout is unavailable, fall back to a plain
   `git checkout -b <type>/<short-slug>` in place. If the main working tree is
   dirty with unrelated changes, ask the user before touching anything.

3. **Understand before writing.** Read the files named in the task and enough
   surrounding code to match its conventions (naming, error handling, test
   style, comment density). If the plan's Steps contradict what the code
   actually looks like, update the Steps to match reality first.

4. **Implement step by step.** Work through the Steps top to bottom, ticking
   each checkbox (`- [x]`) as it lands. Write tests alongside the code, not
   as an afterthought:
   - unit tests for new logic with meaningful branches or edge cases;
   - integration or end-to-end tests that exercise the feature the way a user
     would (preferred over isolated unit tests where practical);
   - a small runnable example when the component warrants one.

   For a BUG FIX, prove the regression test against the bug: demonstrate
   it failing on the pre-fix behavior (a temporary revert or sabotage of
   the fix) and record the failing numbers in TASK.md before trusting it.
   A/B safety rule: COMMIT the fix before applying any sabotage, so the
   revert (`git checkout <file>`) restores the fix and not the branch
   base - a file-level checkout against an uncommitted tree has destroyed
   finished work before. And when a test rig models scheduling or clock
   behavior, mirror the production entity's scheduling-relevant components
   (interpolation opt-ins, sync configs); a clean trace on a non-faithful
   rig is not evidence.

   When the change warrants written documentation (new component, changed
   behavior, design decision worth explaining), write it as
   `tasks/<id>/NOTES.md` next to TASK.md, or update the relevant reference
   doc in `docs/`. Do not scatter README fragments around the tree.

5. **Verify.** Run the project's full check suite: tests, linter, formatter,
   type checker, build - whatever the project defines. Fix what breaks. Do
   not report success on the strength of the diff alone; the tests must
   actually pass, and if some fail, say so with the output. Every
   verification must be able to fail: if a check would still pass with the
   mechanism deleted, it proves nothing - replace it with one that can.

6. **Close the task.** In TASK.md set STATUS to `CLOSED` and append to the
   description:
   - what changed and why, including alternatives considered;
   - difficulties or bugs hit along the way and how they were diagnosed;
   - for a diagnostic or falsification close, the exact evidence rig
     (systems run, command path, components) - without it the evidence
     misleads the next session;
   - brief self-reflection: what could have gone better, what to do
     differently next time. Future sessions read this.

7. **Commit and report.** Commit the code and the TASK.md changes together on
   the feature branch (inside the worktree); use several focused commits if
   the steps form natural units. These commits are the branch's working
   history for review - when `/flow` merges the approved branch it squashes
   them into a single commit on the default branch, so the durable record of
   the task is TASK.md and that squash commit, not the intermediate messages;
   keep the commits focused for the reviewer without agonizing over wording
   that will be collapsed. Then report: worktree path, branch name, task ID,
   summary of the change, and test results. Leave the worktree in place - the
   branch is now ready for `/review`. Do not merge into the default branch,
   remove the worktree, or push unless the user asks.

## Addressing Review Feedback

When `/review` has left a `tasks/<id>/REVIEW.md` with a REQUEST_CHANGES
verdict, addressing it is also `/work`'s job:

1. Stay in the same worktree on the same feature branch. Read the latest
   round's findings.
2. For each finding that is not ticked: either fix it and write
   `Response: fixed in <commit>` on its Response line, or push back with
   concrete reasoning if you believe the finding is wrong. Never tick the
   checkboxes yourself; those belong to the reviewer.
3. Re-run the full check suite after the fixes, commit (including REVIEW.md
   with the responses), and hand the branch back for the next review round.

## Syncing with the Default Branch

A feature branch cannot land on the default branch until it is up to date with
it, exactly like a pull request that must be current with its base before it
merges. When the default branch has moved on since the branch was cut (other
tasks landed there), sync before merging:

1. In the worktree, merge the default branch into the feature branch
   (`git merge <default>`, the local default branch - not `origin/*` when the
   workflow does not push). Do this on the branch so that any conflicts are
   resolved here, not on the default branch.
2. Resolve conflicts on the branch and commit the merge, then re-run the full
   check suite (step 5's verify) on the updated branch. Fix whatever the merge
   broke; the branch is only ready to merge back once it is green and
   `git merge-base --is-ancestor <default> <branch>` succeeds.

Only then is the branch ready to merge back. `/work` itself does not merge into
the default branch - that stays the caller's call (`/flow` does it as its
squash-merge step) - but keeping the branch current is branch hygiene `/work`
owns, whether or not flow is driving.

## Guidelines

- One task per worktree/branch. If mid-implementation you discover unrelated
  work, create a new tatr task for it instead of widening the diff.
- Before closing a task that deletes, moves, or swaps a mechanism or marker,
  grep the workspace for (1) its symbol names, (2) its describing words, and
  (3) everything that observes or queries it - including comments, docs,
  examples, tests, and the CHANGELOG. Silent consumers outlive clean symbol
  sweeps.
- Any commit made in the shared main checkout (not a worktree) starts with
  `git branch --show-current` - parallel sessions can move its HEAD.
- Follow the repo's existing patterns before inventing new ones; consistency
  beats local elegance.
- Do not weaken or delete failing tests to get to green; fix the code, or if
  the test is genuinely wrong, say so explicitly in the task notes.
- Keep TASK.md truthful at all times: checkboxes reflect what is actually
  done, and Steps reflect the plan as executed, not as first written.
- If the task turns out to be much larger than planned, stop and split it
  into new tasks rather than delivering a half-working mega-change.

## Relationship to Planning and Review

`/plan` produces the task with its Steps checklist; `/work` consumes it. If a
task has no Steps section (created ad hoc, not via planning), write one first
following the plan skill's format, then implement it. Planning and working in
the same session is fine, but the TASK.md is still the source of truth, not
the conversation.

After implementation, `/review` critiques the branch and `/work` addresses
the findings, cycling until the review verdict is APPROVE. Only close the
loop with the user (merge, push) when they ask.
