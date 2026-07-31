---
name: review
description: Critique a feature branch against its tatr task and drive rounds to a verdict. Use for `/review` or when a branch is ready for critique.
---

# Review - Critique a Feature Branch

Judge; do not patch. `work` owns fixes.

## Workflow

1. Read `git diff <default>...<branch>` and
   `tatr context <id> --phase review`. Story, Steps, and DoD are the spec. Run
   checks from `cd "$(sprout show <feature>)"`.
2. For substantive round 1, use a reviewer outside the implementation
   context. Its prompt contains only task ID, branch/worktree, dimensions, and
   record format. The primary reruns checks and independently re-derives at
   least one load-bearing claim before accepting findings. Record reviewer
   identity; explain any trivial-diff in-session exception.
3. Verify every task and implementation claim. Write findings in REVIEW.md;
   each needs severity, `file:line`, and an actionable change.
4. Verdict: REQUEST_CHANGES for any open BLOCKER/MAJOR, otherwise APPROVE.
   List open `manual:` items as pending user checks; they do not block
   APPROVE.
5. Later rounds keep the out-of-context default unless an exception is
   recorded. Verify Responses and tick only confirmed fixes. Accept sound
   pushback. Add findings only for fix regressions. Ask the user after three
   disputed rounds. APPROVE ends review.
6. Commit REVIEW.md after every round.

## Rules

- Review the diff, not pre-existing repository problems; create tasks for
  those.
- Severity reflects impact, not effort. No invented nits.
- Re-derive out-of-context claims; shared assumptions survive summaries.

## Output

Findings first by severity, then verdict and pending manual items. Outside
findings: at most 150 words. On APPROVE, `tatr flow <id>` moves to
COMPOUNDING.

## Load on demand

- judging correctness, spec, tests, design, docs, or honesty -> `dimensions.md`
- writing a round, finding, severity, or verdict -> `rounds.md`
- auth, secrets, migrations, concurrency, public API, shared infrastructure, or broad contract -> `lanes.md`
