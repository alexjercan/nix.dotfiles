# Decision: Where the checkpoint handoff lives

- DATE: 20260731-203719
- STATUS: ACCEPTED
- TASK: 20260731-174352
- TAGS: skills, flow, budget

## Context

The Story wants a worker checkpoint to be a first-class flow handoff, and
20260731-174348's round-1 reviewer named the gap precisely: `flow/SKILL.md`'s
Route table has no checkpoint row, and `flow/resume.md` covers only the
receiving side. The obvious fix is a Route row.

It does not fit. `check.sh` enforces `BUDGET_ROUTER_BODY=300` on the flow
body, and the body measured exactly 300. A Route row costs 18 words, four of
them the table pipes (`measure-the-empty-structure`). Re-reading the body for
slack found about 4 words that could go without retiring a rule - the flow
router is the densest surface in the suite, and nearly every sentence in it
carries an imperative.

## Decision

Route the CONDITION from `flow/SKILL.md` and keep the PROTOCOL in
`flow/resume.md`. The `## Load on demand` pointer becomes "at a context
checkpoint, or resuming after `/clear` or context loss -> `resume.md`", which
costs 3 words and is paid for by three one-word tightenings that retire no
rule. The body measures 300 before and 300 after: the trade is exactly net
zero, not a saving.
`resume.md` is retitled to cover both directions and gains the outgoing half.

Building this from scratch today, it is still the right shape: the checkpoint
and the resume are two ends of one protocol, and a reader who needs either
needs the other. Splitting them across a table row and a reference would have
put one end in the always-loaded body and the other behind a pointer, which is
the arrangement that lets two halves drift.

## Alternatives considered

- Raise `BUDGET_ROUTER_BODY` from 300 to 320 and add the row. Rejected by the
  user. The Epic's own final Done Means says every changed skill stays inside
  its measured budget; a task that moves the cap when the cap is inconvenient
  makes the gate advisory. Cost of rejecting: the Route table does not name
  the checkpoint, so a reader scanning only the table will not see it - the
  pointer condition is the mitigation.
- Merge the two REVIEWING rows to pay for the checkpoint row. Rejected by the
  user. It buys the row at the price of compressing a routing rule that
  currently distinguishes APPROVE from REQUEST_CHANGES, a live distinction the
  fix loop depends on.
- Do nothing and leave the handoff undocumented. Rejected: 20260731-174348
  already ships a checkpoint trigger, so the outgoing half exists whether or
  not it is written down. Deferring costs a protocol every agent guesses
  differently.

## Consequences

Easier: `resume.md` owns one coherent protocol end to end, which is what let
the duplication against `work/delegation.md` be found and removed in the same
task.

Harder: `flow/SKILL.md` is at exactly 300/300 with no headroom. The next rule
that genuinely belongs in the Route table cannot be added by editing - it will
force a budget decision or a restructure. This task avoided that only because
it had somewhere else to put the protocol; the next one may not.
