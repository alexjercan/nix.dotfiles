---
name: flow
description: Run understand, plan, work, review, and compound as one autonomous workflow. Use for /flow.
disable-model-invocation: true
---

# Flow

Take a task from problem to landed implementation.

## Workflow

1. `understand` -> `NOTES.md`.
2. `plan` -> Steps and DoD.
3. Create a task worktree with `sprout`.
4. `work` -> implement and verify.
5. `review` -> `REVIEW.md`.
6. `REQUEST_CHANGES` -> `work`, then review again.
7. `APPROVE` -> `compound` -> `RETRO.md`.
8. `sprout sync`, verify, then `sprout land`.

## Rules

* Run autonomously. Follow each skill and its artifact handoffs.
* One task per worktree.
* Ask only for understanding input, `human:` proofs, consequential ambiguity, or destructive/external actions.
* Review must approve before compound or landing.
* Run final verification after sync.
* Never land with unresolved findings or failed checks.
* Do not push.
