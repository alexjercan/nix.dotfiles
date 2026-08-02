---
name: review
description: Critique a feature branch against its tatr task and drive rounds to a verdict. Use for `/review` or when a branch is ready for critique.
---

# Review - Critique a Feature Branch

Judge; do not patch. `work` owns fixes.

## Workflow

1. Read `git diff <default>...<branch>` and
   `tatr -r <task-root> context <id> --phase review`. Story, Steps, DoD and
   the applicable `AGENTS.md` files are the spec. Run checks from
   `cd "$(sprout show <feature>)"`.
2. For substantive round 1, use a reviewer outside the implementation
   context. Its prompt contains only task ID, branch/worktree, dimensions, and
   record format. A fresh `/flow <id>` session that starts at REVIEWING counts
   as the outside reviewer; do not spawn another by default. The primary reruns
   checks and independently re-derives at least one load-bearing claim before
   accepting findings. Record reviewer identity; explain exceptions.
3. Verify every task and implementation claim. Write findings in REVIEW.md;
   each needs severity, `file:line`, and an actionable change.
4. Verdict: REQUEST_CHANGES for any open BLOCKER/MAJOR, otherwise APPROVE.
   List open `manual:` items as pending user checks; they do not block
   APPROVE.
5. Later rounds keep the out-of-context default unless an exception is
   recorded. Verify Responses and tick only confirmed fixes. Accept sound
   pushback. Add findings only for fix regressions. Stop after three disputed
   rounds; work owns every third-round continuation gate.
6. Commit REVIEW.md after every round. APPROVE -> COMPOUNDING; run
   `tatr -r <task-root> flow <id>`, which earns the `REVIEW` gate, and
   dispatch compound. REQUEST_CHANGES dispatches work.

## Rules

- Review the diff, not pre-existing repository problems; create tasks for
  those.
- Severity reflects impact, not effort. Ask the counterfactual: knowing
  current constraints, would we build this route from scratch? An alternative
  must preserve behavior and name the concepts, branches or indirection it
  deletes; one you cannot state that way is an invented nit.
- Re-derive out-of-context claims; shared assumptions survive summaries.

## Output

Findings first by severity, then verdict, pending manual items, and inspection
commands. Outside findings: at most 150 words. APPROVE proceeds directly to
COMPOUNDING and `compound`; REQUEST_CHANGES routes to `work`.

## Load on demand

- judging correctness, spec, tests, design, docs, or honesty -> `dimensions.md`
- writing a round, finding, severity, or verdict -> `rounds.md`
- auth, secrets, migrations, concurrency, public API, shared infrastructure, or broad contract -> `lanes.md`
