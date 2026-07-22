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

2. **Round 1 comes from out of context by default.** For any substantive
   branch, the round-1 findings are produced by a reviewer that has NOT
   seen the implementing session: a fresh subagent, a /code-review pass in
   a mode that spawns fresh agents (not in-conversation analysis), or a
   separate session. Substantive is judged by consequence, not file type: a
   docs-only diff that defines process or behavior (a skill file, a spec)
   is substantive; only typo-level or cosmetic-wording fixes are trivial.
   The reviewer's prompt contains only the task id, the branch and worktree
   path, the REVIEW.md format and the review dimensions below - never the
   implementing conversation or its summaries (they carry the implementer's
   assumptions, which are exactly what must not leak). The out-of-context
   reviewer RETURNS findings; the in-session pass writes and commits the
   merged round, runs the check suite itself, and re-verifies at least one
   load-bearing claim of the findings before adopting them. For a trivial
   diff an in-session-only round is fine; on a substantive branch it is an
   exception (e.g. no out-of-context mechanism available) - either way the
   round header records it and why.

3. **Review dimensions** - for whichever reviewer runs them. Do not trust
   the implementer's summary; verify.
   - Correctness: bugs, edge cases, error handling, concurrency, security.
   - Spec: does the diff actually deliver the Goal? Is every ticked step
     really done? Run each DoD item's named proof yourself - execute every
     `test:` and `cmd:` proof and confirm it passes on the stated criterion;
     do not take the implementer's word that it does. Each open `manual:`
     proof is not yours to resolve: note it as a pending user check to list
     with the verdict.
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
     missed reuse. If the diff makes a load-bearing architectural choice a cold
     reader would need the *why* of, check it has a `DECISION.md` (plan skill)
     - and if it changes an earlier decision, that the supersede link is
     present on both records. A missing record for a genuinely load-bearing
     choice is a MINOR finding, not a BLOCKER.
   - Docs: behavior changes worth documenting are covered in the task's
     `NOTES.md` or the relevant reference doc in `docs/`, and the
     doc-surface sweep ran (work skill, verify step): spot-check it by
     picking one renamed or changed symbol/flag from the diff and grepping
     README, `docs/`, AGENTS.md and the skill files for stale mentions.
   - Honesty: TASK.md notes match what the code actually does.

4. **Write the findings.** Create or append to `tasks/<id>/REVIEW.md` (format
   below). Every finding gets a severity, a `file:line` reference, and a
   concrete suggested change - "rename X to Y", not "naming could be better".
   Use ONLY the four canonical severities - `BLOCKER`, `MAJOR`, `MINOR`, `NIT`;
   never invent `LOW`/`INFO`/`OBSERVATION` or similar. `tatr check` parses every
   `- [ ] Rn.n (SEVERITY) ...` line in REVIEW.md as a finding and flags any
   severity outside the four as `bad-severity`, so a non-canonical label fails
   conformance after the task lands. Verification notes, observations and
   "what I checked" prose are NOT findings: write them as plain prose (or a
   plain `-` bullet without the `Rn.n (SEVERITY)` shape), reserving the
   checkbox-finding form for the four severities alone.

5. **Issue the verdict.** `REQUEST_CHANGES` if any BLOCKER or MAJOR finding
   is open; `APPROVE` otherwise (open MINOR/NIT findings may be left to the
   implementer's discretion). Alongside the verdict, list the task's open
   `manual:` DoD items as pending user checks - APPROVE does not resolve them;
   they are the human-acceptance gate the user clears later (batched at the
   flow Finish), so an APPROVE with manual items still open is normal, not a
   contradiction. Record the verdict in the round header and tell the user.
   On APPROVE the cycle ends; merging is the user's call.

6. **Re-review rounds.** When `/work` hands the branch back, verify each
   response against the new diff - tick the finding's checkbox only when you
   confirmed it is resolved. Re-review rounds keep the same reviewer
   default: resume the out-of-context reviewer against the new diff (the
   in-session pass supplements), and record `REVIEWER:` per round. Accept
   reasoned pushback when it is convincing; do not relitigate settled
   findings. Add new findings only for problems the new changes introduced.
   If the same finding is still disputed after three rounds, stop and
   surface the disagreement to the user.

## REVIEW.md Format

```markdown
# Review: Add rate limiting to the API

- TASK: 20260703-101500
- BRANCH: feature/api-rate-limiting

## Round 1

- VERDICT: REQUEST_CHANGES
- REVIEWER: out-of-context

- [ ] R1.1 (BLOCKER) src/server.rs:88 - the limiter is constructed per
  request, so the bucket never accumulates; hoist it into shared app state.
  - Response:
- [ ] R1.2 (MINOR) src/middleware/ratelimit.rs:14 - `check2` does not match
  repo naming; rename to `try_acquire`.
  - Response:
```

- Rounds are appended (`## Round 2`, ...), never rewritten; the file is the
  review history.
- `REVIEWER:` records who produced the round's findings: `out-of-context`
  (the default - a reviewer with no sight of the implementing session) or
  `in-session (<why>)` - a trivial diff, or the recorded exception on a
  substantive one.
- Finding IDs are `R<round>.<n>`. Severities are exactly these four and no
  others (`tatr check` rejects any other token as `bad-severity`): `BLOCKER`
  (broken, unsafe, or does not deliver the Goal), `MAJOR` (design flaw or
  missing test that should not ship), `MINOR` (worth fixing, not blocking),
  `NIT` (take it or leave it). A note that is not one of these is not a finding
  - write it as plain prose, not a `- [ ] Rn.n (SEVERITY)` line.
- The implementer fills the `Response:` line. Checkboxes belong to the
  review side: whoever the round's `REVIEWER:` line names verifies a fix
  before its checkbox is ticked (for an out-of-context round, the
  in-session pass records the tick on that reviewer's confirmation - the
  out-of-context reviewer itself never writes or commits on the branch).

## Guidelines

- Be specific and actionable; a finding the implementer cannot act on is
  noise.
- Do not invent nits to look thorough. A clean diff deserves a short round
  and an APPROVE.
- The out-of-context default exists because a shared session has a
  structural blind spot: the reviewer inherits the implementer's assumptions
  along with the context, and prompt-level "review skeptically" nudges do
  not remove them (nova-protocol's ledger had logged the out-of-context
  lesson 31 times by 2026-07-20 without it ever becoming the default; the
  default's first use here caught an unfailable test the implementing
  session had sabotage-tested around, 20260720-152433). The blind spot
  applies to the supplement too: re-derive at least one load-bearing claim
  yourself rather than adopting the out-of-context round wholesale.
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
