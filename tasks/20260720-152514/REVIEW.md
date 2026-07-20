# Review: Ledger lifecycle: RETIRED marker, promotion order, shrink-on-absorb

- TASK: 20260720-152514
- BRANCH: feature/ledger-lifecycle

## Round 1

- VERDICT: APPROVE
- REVIEWER: out-of-context (fresh-context subagent; prompt contained only
  the task id, branch, worktree path, the real binary's location and review
  instructions)

No BLOCKER/MAJOR findings. Reviewer verified the lint-exemption design
against the real binary (a fixture with the exact absorbed and RETIRED
annotation forms outside Pending promotions: all exempt, bare control
flagged), both DoD greps, all four Steps against the diff, cross-skill
order/phrasing identity between compound step 6 and lessons step 4, and
the no-contradiction checks (pruning removes an entry, not the ledger;
wipe stays scratch-only).

Open MINOR/NIT findings, all taken at the implementer's discretion in the
same branch (per the open-MINOR rule; wordings are the reviewer's own
suggestions):

- [x] R1.1 (MINOR) pruning was described but never instructed, and step
  6's report list omitted prunings.
  - Response: taken - step 4 now instructs the release-level prune with
    the "When to run" cross-reference; step 6 reports pruned entries.
- [x] R1.2 (MINOR) "DELETED in the same change" unsatisfiable cross-repo
  (the motivating tatr case is exactly that).
  - Response: taken - paired-change clause added; absorption is not done
    until both land.
- [x] R1.3 (MINOR) the RETIRED example's body was meta-commentary,
  modeling history-destruction (rule-and-example-must-agree).
  - Response: taken - stale-harness got a real lesson sentence; step 4
    also now says "keeping the lesson's own sentence intact as history".
- [x] R1.4 (MINOR) compound step 5 and Guidelines kept the superseded
  prose-first framing.
  - Response: taken - both now name tool guard/template first and point at
    step 6 for the order.
- [x] R1.5 (NIT) preamble said "until the user promotes" over a list where
  two annotations are not promotions.
  - Response: taken - "until a lifecycle event annotates them".
- [x] R1.6 (NIT) annotation placeholder said <tool> where the rule covers
  templates.
  - Response: taken - "<tool or template>" in rule and preamble.

Checkboxes ticked by the in-session pass on the reviewer's own suggested
wordings; the APPROVE verdict predates and stands over these discretionary
edits.
