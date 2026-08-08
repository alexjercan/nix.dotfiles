---
name: work
description: Implement a task or request test-first. Use for /work.
disable-model-invocation: true
---

# Work

Implement the requested change.

## Input

* Task provided -> follow its `## Steps` and `## Definition of Done`.
* Open findings in `REVIEW.md` -> address them first.
* No task -> implement the request directly.

## Rules

* Use red -> green -> refactor when behavior has a meaningful automated test.
* Bug -> reproduce with a failing test before fixing it when practical.
* Prefer tests at the behavior boundary. Add unit tests for unit-shaped seams.
* Docs, prose, simple configuration, packaging, and mechanical changes do not
  require invented tests. Use the most direct `cmd:` or `human:` proof.
* Follow `CONVENTIONS.md` and `AGENTS.md`.
* Keep scope focused. No unrelated cleanup or speculative abstractions.
* Run relevant tests and checks after implementation.
* Task provided -> verify every `test:` and `cmd:` DoD proof. Leave `human:` for the user.
* Address every open review finding or record concrete pushback.
* Do not mark review findings complete. Review owns verification.
