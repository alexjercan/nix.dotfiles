---
name: work
description: Implement one planned task in a sprout worktree, test-first, and verify it. Use for `/work` or to address review feedback.
---

# Work - Implement a Task on a Feature Branch

Deliver the solution a serious developer would ship, not the minimum diff that
appears to work.

## Workflow

1. **Pick the task.** Use the ID the user or `flow` gave, else the top
   `tatr ls --sort priority` OPEN task. Read it with
   `tatr context <id> --phase work`.

2. **Sprout.** With HEAD on the intended base:

   ```bash
   cd "$(sprout new <type>/<short-slug>)"
   tatr flow <id> --to WORKING
   ```

   `<type>` comes from the tags (`feature`, `bug` -> `fix`, `refactor`), the
   slug from the title. `tatr flow --to WORKING` is the gate: it refuses a
   task without `PLAN STATUS: APPROVED`, with open dependencies, or claimed by
   another session. A refusal means plan it first - do not hand-edit TASK.md
   around it.

   If the main working tree is dirty with unrelated changes, ask the user
   before touching anything. If sprout is unavailable, fall back to a plain
   `git checkout -b <type>/<short-slug>` in place.

   The shell cwd does NOT persist between commands. Drive every edit and git
   call by absolute worktree path or `git -C <worktree>`, and never chain
   operations across two repositories in one call.

3. **Understand before writing.** Read the files the task names plus enough
   surrounding code to match its conventions. If the Steps contradict the
   code, fix the Steps first.

4. **Implement test-first.** Work the Steps top to bottom, ticking each box as
   it lands. For every `test:` or `cmd:` proof, encode the criterion, run it,
   and watch it FAIL for the right reason before writing the implementation.
   Then the minimal code to make it pass, then refactor green.

   Prefer the example/integration altitude for that first test: a small
   runnable example or harness-level test that drives the feature the way a
   user would, isolated to the one system under test. Drop to a unit test only
   when the seam is genuinely unit-shaped.

   A `manual:` proof stays a human check and is reported as pending, never
   self-ticked.

   Documentation is part of the change: every doc surface the diff invalidates
   is updated in the same task. New written documentation goes in
   `tasks/<id>/NOTES.md` or the project's reference docs. A load-bearing
   choice the plan did not record gets a DECISION.md (plan skill's
   `decision.md`).

5. **Verify.** The full check suite plus every proof from
   `tatr proofs <id>`, run bare.

6. **Close out.** Append to TASK.md what changed and why, alternatives
   considered, difficulties and how they were diagnosed, the evidence rig for
   a diagnostic close, and a short self-reflection. Commit code and TASK.md
   together on the feature branch; several focused commits are fine, since
   landing squashes them.

   `tatr flow <id>` moves WORKING -> REVIEWING. The task stays IN_PROGRESS
   through review and compound and closes only at DONE.


## Guidelines

- One task per worktree. Unrelated work found mid-implementation becomes a new
  tatr task created in this worktree, not a wider diff.
- Tick a step only when EVERY clause of it is done; re-read the literal text
  first. Otherwise split the step, or amend its text in the same edit.
- Do not weaken or delete a failing test to reach green.
- Any commit in the shared main checkout starts with `git branch
  --show-current`; parallel sessions move its HEAD.
- A grep sweep feeding a checklist is never head-truncated; dump it in full
  and count the matches.
- Compose test rigs from the production helpers, not hand-written
  re-derivations; grep for an existing rig of the same kind first.
- If the task turns out much larger than planned, stop and split it.

## Output

Worktree path, branch, task ID, one-line summary, proof results - 150 words or
fewer. Leave the worktree in place. Do not merge, remove it, or push.

## Load on demand

Read one ONLY when its condition holds. Never preload them.

- the task is a bug, crash, regression or falsification -> `bug.md`
- running the check suite and the doc-surface sweep -> `verify.md`
- the review returned a REQUEST_CHANGES verdict -> `review-feedback.md`
