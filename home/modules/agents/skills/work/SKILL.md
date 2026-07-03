---
name: work
description: Implement a planned tatr task end to end on a feature branch, with tests and verification. Use this skill when the user asks to start work with `/work`, to implement or pick up a task from the backlog, or to execute a plan created earlier. It takes a tatr task (given by ID or chosen from the backlog), creates a feature branch, works through the task's steps, and delivers a working, tested solution.
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

2. **Start the task.** Set STATUS to `IN_PROGRESS` in TASK.md. Create a
   feature branch off the default branch:

   ```bash
   git checkout -b <type>/<short-slug>
   ```

   Derive `<type>` from the task's tags (`feature`, `bug` -> `fix`,
   `refactor`, ...) and `<short-slug>` from the title, e.g.
   `feature/api-rate-limiting`. If the working tree is dirty with unrelated
   changes, ask the user before touching anything.

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

5. **Verify.** Run the project's full check suite: tests, linter, formatter,
   type checker, build - whatever the project defines. Fix what breaks. Do
   not report success on the strength of the diff alone; the tests must
   actually pass, and if some fail, say so with the output.

6. **Close the task.** In TASK.md set STATUS to `CLOSED` and append to the
   description:
   - what changed and why, including alternatives considered;
   - difficulties or bugs hit along the way and how they were diagnosed;
   - brief self-reflection: what could have gone better, what to do
     differently next time. Future sessions read this.

7. **Commit and report.** Commit the code and the TASK.md changes together on
   the feature branch; use several focused commits if the steps form natural
   units. Then report: branch name, task ID, summary of the change, and test
   results. Do not merge into the default branch or push unless the user
   asks.

## Guidelines

- One task per branch. If mid-implementation you discover unrelated work,
  create a new tatr task for it instead of widening the diff.
- Follow the repo's existing patterns before inventing new ones; consistency
  beats local elegance.
- Do not weaken or delete failing tests to get to green; fix the code, or if
  the test is genuinely wrong, say so explicitly in the task notes.
- Keep TASK.md truthful at all times: checkboxes reflect what is actually
  done, and Steps reflect the plan as executed, not as first written.
- If the task turns out to be much larger than planned, stop and split it
  into new tasks rather than delivering a half-working mega-change.

## Relationship to Planning

`/plan` produces the task with its Steps checklist; `/work` consumes it. If a
task has no Steps section (created ad hoc, not via planning), write one first
following the plan skill's format, then implement it. Planning and working in
the same session is fine, but the TASK.md is still the source of truth, not
the conversation.
