---
name: review
description: Critically review the feature branch produced by /work for a tatr task, and drive the review cycle until the work is approved. Use this skill when the user asks to review with `/review`, when a /work implementation is ready for critique, or when re-reviewing after review feedback was addressed. It writes findings to a REVIEW.md next to the task, with severities and concrete suggested changes, and issues a REQUEST_CHANGES or APPROVE verdict.
---

# Review - Critique the Work Like a Real PR Review

Review is the step after implementation: read the feature branch that `/work`
produced with fresh, skeptical eyes and produce a critique the implementer
acts on. Findings live in `tasks/<id>/REVIEW.md`, versioned next to TASK.md,
and the cycle repeats (review, address, re-review) until the verdict is
APPROVE - like PR review rounds between real developers.

The reviewer's job is judgment, not politeness. It is also not to patch the
code: the reviewer never commits fixes, only findings. `/work` does the
fixing.

## Workflow

1. **Locate the work.** Identify the task (ID from the user, or the task the
   feature branch belongs to) and diff the branch against the default branch
   (`git diff <default>...<branch>`). The branch usually lives in a sprout
   worktree; the diff works from anywhere in the repo since the refs are
   shared, but run the check suite in the worktree
   (`cd "$(sprout show <feature>)"`) where the code is actually checked out.
   Read TASK.md fully - Goal, Steps and Notes are the spec the diff is judged
   against.

2. **Review with fresh eyes.** Do not trust the implementer's summary; verify.
   - Correctness: bugs, edge cases, error handling, concurrency, security.
   - Spec: does the diff actually deliver the Goal? Is every ticked step
     really done?
   - Tests: run the full check suite yourself. Are the tests meaningful (they
     assert behavior, not just execute code)? Were any existing tests
     weakened or deleted to get to green? Any "X stays zero / nothing
     happens" assertion needs a paired delivery guard proving the
     provoking stimulus actually fired - a steady hull and a dead engine
     must not be indistinguishable. Ask of each new test: would it fail
     with the fix deleted? A test that cannot fail (often one copied from
     a neighbor) verifies nothing. A bug fix must be pinned at its OWN
     boundary (a unit test that fails under the bug), not only by a
     downstream end-to-end test - and when a refactor changes how an
     invariant is enforced, the invariant gets re-pinned on the new
     mechanism, not the old assertion massaged until it passes.
   - Design: consistency with the repo's conventions, needless complexity,
     missed reuse.
   - Docs: behavior changes worth documenting are covered in the task's
     `NOTES.md` or the relevant reference doc in `docs/`.
   - Honesty: TASK.md notes match what the code actually does.

3. **Write the findings.** Create or append to `tasks/<id>/REVIEW.md` (format
   below). Every finding gets a severity, a `file:line` reference, and a
   concrete suggested change - "rename X to Y", not "naming could be better".

4. **Issue the verdict.** `REQUEST_CHANGES` if any BLOCKER or MAJOR finding
   is open; `APPROVE` otherwise (open MINOR/NIT findings may be left to the
   implementer's discretion). Record the verdict in the round header and tell
   the user. On APPROVE the cycle ends; merging is the user's call.

5. **Re-review rounds.** When `/work` hands the branch back, verify each
   response against the new diff - tick the finding's checkbox only when you
   confirmed it is resolved. Accept reasoned pushback when it is convincing;
   do not relitigate settled findings. Add new findings only for problems the
   new changes introduced. If the same finding is still disputed after three
   rounds, stop and surface the disagreement to the user.

## REVIEW.md Format

```markdown
# Review: Add rate limiting to the API

- TASK: 20260703-101500
- BRANCH: feature/api-rate-limiting

## Round 1

- VERDICT: REQUEST_CHANGES

- [ ] R1.1 (BLOCKER) src/server.rs:88 - the limiter is constructed per
  request, so the bucket never accumulates; hoist it into shared app state.
  - Response:
- [ ] R1.2 (MINOR) src/middleware/ratelimit.rs:14 - `check2` does not match
  repo naming; rename to `try_acquire`.
  - Response:
```

- Rounds are appended (`## Round 2`, ...), never rewritten; the file is the
  review history.
- Finding IDs are `R<round>.<n>`. Severities: `BLOCKER` (broken, unsafe, or
  does not deliver the Goal), `MAJOR` (design flaw or missing test that
  should not ship), `MINOR` (worth fixing, not blocking), `NIT` (take it or
  leave it).
- The implementer fills the `Response:` line; the reviewer owns the
  checkboxes and ticks them only after verifying the fix.

## Guidelines

- Be specific and actionable; a finding the implementer cannot act on is
  noise.
- Do not invent nits to look thorough. A clean diff deserves a short round
  and an APPROVE.
- When implementer and reviewer share one session, the review has a
  structural blind spot. For any substantial branch, independently
  re-derive or re-verify at least one load-bearing claim (a formula, an
  ordering, a hierarchy assumption) instead of reading the diff alone;
  for large changes consider an out-of-context pass (/code-review).
- Review the diff, not the repo. Pre-existing problems you notice become new
  tatr tasks, not blockers on this branch.
- Severity reflects impact, not effort to fix.
- Commit REVIEW.md on the feature branch after each round so the history
  travels with the work.

## Relationship to /work

`/work` implements, `/review` critiques, `/work` addresses, until APPROVE.
When addressing feedback, `/work` fixes each open finding on the same branch
(or pushes back with reasoning in the Response line), re-runs the checks,
commits, and hands the branch back for the next round.
