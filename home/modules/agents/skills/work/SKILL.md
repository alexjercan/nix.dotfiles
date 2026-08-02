---
name: work
description: Implement one planned task in a sprout worktree, test-first, and verify it. Use for `/work` or to address review feedback.
---

# Work - Implement a Planned Task

Ship the maintainable solution, not the smallest plausible diff.

## Workflow

1. Use the given ID, else the highest-priority OPEN task. Read
   `tatr -r <task-root> context <id> --phase work`.
2. From the intended base, run `sprout new <type>/<slug> --task <id>`, then
   `tatr -r <task-root> flow <id> --to WORKING`. Tags choose type
   (`bug` -> `fix`, `refactor` -> `refactor`). Ask before touching unrelated
   dirty main-tree changes. If sprout is unavailable, use a local feature
   branch. The new worktree becomes `<task-root>`. Shell cwd does not persist:
   use absolute paths for every edit/git/tatr call.
3. Read named and neighboring code. Correct Steps that contradict it before
   implementation.
4. For each `test:` or `cmd:` proof, make it fail for the intended reason,
   implement minimally, then refactor green. Prefer an integration/example
   boundary; use a unit test only for a unit-shaped seam. Never weaken a test.
   Keep `manual:` pending. Code comments are only for docstrings or essential
   implementation notes; put explanatory prose in task records. Never prune a
   comment that guards a value or explains a non-obvious setting. Update
   invalidated docs; record new load-bearing choices in DECISION.md.
5. Run the full suite and every `tatr -r <task-root> proofs <id>` proof.
6. Tick a Step only after re-reading and completing every clause. Add TASK.md
   close-out: what/why, alternatives, difficulties/diagnosis, evidence, and
   reflection. Commit implementation and records together.
   Initial work returns WORK_DONE without a transition.
   Flow owns approval to REVIEWING; `review-feedback.md` owns later handoffs.

## Rules

- One task per worktree. New unrelated work becomes a task there.
- Split work that materially exceeds the plan.
- Before a shared-main commit, check its branch.
- Never truncate a checklist grep. Reuse production helpers in test rigs.
- Checkpoint at 120K visible context tokens, hand off at 150K. When token
  usage is unavailable, trigger on the first compaction warning or a working
  set that no longer fits one focused pass. `flow/resume.md` owns the handoff.

## Output

Worktree, branch, task ID, changed files, proof results, confidence/risk, and
inspection commands; at most 150 words. Return the gate status
`WORK_DONE <id>` without changing lifecycle state. Leave the worktree. Do not
merge, remove, or push.

## Load on demand

- under context pressure, or a bounded Step a subagent could own -> `delegation.md`
- bug, crash, regression, or falsification -> `bug.md`
- running checks and the doc-surface sweep -> `verify.md`
- review returned REQUEST_CHANGES -> `review-feedback.md`
