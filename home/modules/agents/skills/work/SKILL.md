---
name: work
description: Implement a task or request. Use for /work.
disable-model-invocation: true
---

# Work

Implement the requested change.

## Input

* Task provided -> use its `## Steps` hints and verify its `## Definition of Done`.
* Open findings in `REVIEW.md` -> address them first.
* No task -> implement the request directly.

## Rules

* Follow `CONVENTIONS.md` and `AGENTS.md`. Use sound engineering practice.
* Keep scope focused. No unrelated cleanup or speculative abstractions.
* Run relevant tests and checks. Leave `(manual)` DoD items to the user.
