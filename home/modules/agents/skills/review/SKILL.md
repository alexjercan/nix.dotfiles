---
name: review
description: Review an implementation for correctness, tests, design, and scope. Use for /review.
disable-model-invocation: true
---

# Review

Review the implementation. Judge; do not patch.

## Input

* Task provided -> review against its Steps and Definition of Done.
* No task -> infer intended behavior from the request and code.
* Review the diff and relevant surrounding code.
* Follow `CONVENTIONS.md` and `AGENTS.md`.

## Review

* Correctness: bugs, edge cases, errors, security, concurrency.
* Tests: meaningful coverage; missing, weakened, or ineffective tests.
* Design: maintainability, ownership, reuse, unnecessary complexity.
* Scope: requested behavior complete; no speculative or unrelated work.
* Docs: changed public behavior documented where needed.
* Honesty: completed Steps and DoD match the implementation.

Verify claims yourself. Run relevant tests, checks, and DoD proofs.

## Findings

Use this format:

```markdown
# Review

## Findings

- [ ] MAJOR `src/foo.py:42` - Validation misses empty values. Validate before persistence.
- [ ] MINOR `src/bar.py:18` - Duplicate parsing logic. Reuse `parse_config`.

## Verdict

REQUEST_CHANGES
```

* Task provided -> maintain `<task-dir>/REVIEW.md`.
* No task -> return the same format to the user.
* Re-check existing open findings first.
* Mark findings complete only after verifying the fix.
* Each finding requires severity, `file:line`, reason, and concrete change.
* `BLOCKER`: broken, unsafe, or requirement missing.
* `MAJOR`: should not ship.
* `MINOR`: worth fixing.
* `NIT`: optional.
* Verdict: `APPROVE` or `REQUEST_CHANGES`.

