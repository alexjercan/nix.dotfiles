# REVIEW.md rounds and findings

Scaffold the record so it passes the lint from the start:

```bash
tatr -r <task-root> scaffold <id> REVIEW
```

## Format

`tatr scaffold` writes the file header and Round 1. Later rounds are APPENDED
by hand - the file is the review history and is never rewritten - numbered from
1 with no gaps (`bad-review-round`):

```markdown
## Round 2

- VERDICT: REQUEST_CHANGES
- REVIEWER: out-of-context

- [ ] R2.1 (BLOCKER) src/server.rs:88 - the limiter is constructed per
  request, so the bucket never accumulates; hoist it into shared app state.
  - Response:
```

## The round-1 subagent handoff

Round 1 always hands off outside this context, to a bounded reviewer like the
implementation subagent in `work/delegation.md`. A high-risk diff may split
into lanes instead.

What it RECEIVES, and nothing else: the task ID, the branch, the worktree path,
the default branch, the review dimensions, and this format. Never the
implementing conversation, its summary, or a description of what was built -
those carry the implementer's assumptions, which are the whole thing the fresh
context exists to exclude.

What it RETURNS: findings only, in the shape above, most severe first, plus any
`Process signal:` bullets and a short list of what it verified and what it
could not. No narrative, no fixes, no writes to any file, no commits. 400 words
or fewer outside the findings themselves.

The recording pass then re-derives at least one load-bearing claim, runs the
check suite itself, and writes and commits the round.

## The four severities

`BLOCKER`, `MAJOR`, `MINOR`, `NIT`. There are no others. `tatr check` parses
every `- [ ] Rn.n (SEVERITY)` line as a finding and rejects any other token as
`bad-severity`, so `LOW`, `INFO` or `OBSERVATION` fails conformance after the
task lands.

- `BLOCKER` - broken, unsafe, or does not deliver the Story.
- `MAJOR` - a design flaw or missing test that should not ship.
- `MINOR` - worth fixing, not blocking.
- `NIT` - take it or leave it.

Verification notes, observations and "what I checked" prose are NOT findings.
Write them as plain prose or a plain `-` bullet, and reserve the
checkbox-finding shape for the four severities alone.

Unexpected scope, a missed task split, or review-driven restructuring is one
such bullet, prefixed `Process signal:` for the retro to mine. It is evidence
about the plan, not a code finding, and never blocks a verdict.

## Required fields

- `- VERDICT:` per round, `APPROVE` or `REQUEST_CHANGES` and nothing else
  (`bad-verdict`). An APPROVE with an unticked BLOCKER or MAJOR is
  `approve-with-open-findings`, and `tatr flow` out of REVIEWING refuses it.
- `- REVIEWER:` per round (`missing-reviewer`): `out-of-context` - a reviewer
  with no sight of the implementing session - or `in-session (<why>)`, reserved
  for a runtime that cannot start a second context.
- Finding IDs are `R<round>.<index>`, in their own round, with no skipped
  index (`bad-finding-id`).

## Who writes what

- The reviewer writes findings and the verdict.
- The implementer fills the `Response:` line, and nothing else.
- The checkbox belongs to the review side: whoever the round's `- REVIEWER:`
  names verifies the fix before its box is ticked. For an out-of-context
  round, the in-session pass records the tick on that reviewer's confirmation
  - the out-of-context reviewer itself never writes or commits on the branch.

## Every finding needs

A severity, a `file:line` reference, and a concrete suggested change. "Rename
X to Y", not "naming could be better".
