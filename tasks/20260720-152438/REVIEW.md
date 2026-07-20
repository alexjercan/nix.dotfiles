# Review: Review skill: out-of-context reviewer is the round-1 default

- TASK: 20260720-152438
- BRANCH: feature/review-ooc-default

## Round 1

- VERDICT: REQUEST_CHANGES
- REVIEWER: out-of-context (fresh-context subagent; prompt contained only
  the task id, branch, worktree path and review instructions)

- [x] R1.1 (MAJOR) review/SKILL.md:29 - the carve-out "(more than a trivial
  typo or docs-only diff)" parses as exempting ALL docs-only diffs; in this
  repo the flagship substantive changes ARE docs-only (skill files,
  including this very branch), so the wording enables the
  everything-is-trivial erosion the default exists to prevent. Suggested:
  define triviality by consequence - a docs-only diff that defines process
  or behavior (a skill file, a spec) is substantive.
  - Response: fixed - carve-out now judges by consequence: "a docs-only diff
    that defines process or behavior (a skill file, a spec) is substantive;
    only typo-level or cosmetic-wording fixes are trivial".
- [x] R1.2 (MINOR) review/SKILL.md:39 - spec deviation on a ticked step:
  TASK.md requires "an in-session-only round on a substantive branch must
  say why" (escape hatch with mandatory justification); the delivered text
  forbids it outright, leaving no sanctioned path when no out-of-context
  mechanism is available. Suggested: add the exception with recorded
  reason, or record the deliberate tightening in the close-out.
  - Response: fixed - the escape hatch is back as specified: an
    in-session-only round on a substantive branch is "an exception (e.g. no
    out-of-context mechanism available)" and the header records why. The
    Steps tick is honest again.
- [x] R1.3 (MINOR) review/SKILL.md:74 - the default is scoped to round 1
  only; step 6 (re-review) gives no REVIEWER guidance for rounds 2+, though
  the cited precedent (20260720-152433) resumed the out-of-context reviewer
  for round 2. Suggested: one sentence in step 6 - re-review rounds keep
  the same reviewer default; REVIEWER recorded per round.
  - Response: fixed - step 6 now says re-review rounds keep the same
    default (resume the out-of-context reviewer against the new diff) and
    REVIEWER is recorded per round.
- [x] R1.4 (MINOR) review/SKILL.md:32 - "/code-review pass" listed
  unqualified as an out-of-context mechanism, but an in-conversation
  /code-review sees exactly the context the definition excludes; only
  fresh-agent modes qualify. Suggested: qualify it.
  - Response: fixed - now "a /code-review pass in a mode that spawns fresh
    agents (not in-conversation analysis)".
- [x] R1.5 (MINOR) review/SKILL.md:65,111 - authorship under the split is
  undefined: who writes/commits REVIEW.md (a subagent should not commit on
  the branch) and who ticks checkboxes now that "the reviewer" is two
  parties. The 152433 precedent resolved it (subagent returns findings,
  orchestrator writes; resumed subagent confirms before ticks) but the
  skill does not capture it. Suggested: state it in steps 2/4 and rework
  the checkbox-ownership format note.
  - Response: fixed - step 2 states the reviewer RETURNS findings and the
    in-session pass writes/commits the merged round; the format note now
    ties checkbox ticks to the round's REVIEWER (in-session records the
    tick on the out-of-context reviewer's confirmation; that reviewer never
    writes or commits on the branch).
- [x] R1.6 (NIT) review/SKILL.md:123 - the "31 times" figure is
  unverifiable from this repo, will rot as nova's ledger grows, and drifts
  from the Story's referent (the slug count, not "that lesson"). Suggested:
  date and scope it, or drop the count.
  - Response: fixed - dated and scoped: "had logged the out-of-context
    lesson 31 times by 2026-07-20 without it ever becoming the default".

Reviewer verification notes: diff touches only the two skill files +
TASK.md; no sibling skill references review steps by number (renumbering
safe); the 20260720-152433 citation verified accurate against its REVIEW.md
and RETRO.md; both DoD greps pass; no non-ASCII introduced; close-out
honest except the R1.2 tick.

## Round 2

- VERDICT: APPROVE
- REVIEWER: out-of-context (same fresh-context subagent, resumed)

All six findings verified resolved against the actual text (not the
responses): consequence-based carve-out closes the docs-only loophole, the
substantive-branch exception is back with recorded reason, re-review rounds
keep the reviewer default, /code-review qualified to fresh-agent modes,
authorship split stated without contradicting the intro's
"never commits fixes" rule, x31 claim dated and scoped. One new NIT (ragged
wrap of the rationale paragraph) - taken in the same commit as these ticks.
