# Review: Wire tatr check into the tatr, compound, flow and lessons skills

- TASK: 20260720-152508
- BRANCH: feature/tatr-check-skills

## Round 1

- VERDICT: REQUEST_CHANGES
- REVIEWER: out-of-context (fresh-context subagent; prompt contained only
  the task id, branch, worktree path, the real binary's location and review
  instructions)

- [x] R1.1 (MAJOR) lessons/SKILL.md:67 - "Detection is mechanical, not
  vigilance" overstates the lint: an annotated count like "(x3, note)" does
  not parse and is invisible to it (verified against the binary). The
  bare-counts convention that makes the sentence true exists only in this
  task's Close-out, which no future session reads - and the repo's own
  ledger already models the annotated form. Suggested: one clause in step 4
  and/or the Ledger format block - counts stay bare until promotion; the
  annotation is the promotion marker.
  - Response: fixed - the bare-counts convention is now in BOTH places a
    future session reads: lessons step 4 ("counts stay BARE until
    promotion... an annotated count is invisible to the lint by design")
    and the Ledger format block preamble. The repo's own annotated x3
    entry is correct under the convention: it IS promoted.
- [x] R1.2 (MINOR) tasks/20260720-152508/TASK.md:21 - step 4 is ticked as
  "the lint replaces the prose reminder (shrink the prose)" but the diff
  removes nothing; the paragraph grew. The wiring is delivered and keeping
  the move-instruction is defensible, but the tick does not match the
  literal step text (the ledger's own tick-against-the-literal-step
  lesson). Suggested: amend the step/Close-out to record the deviation, or
  restructure while applying R1.1.
  - Response: fixed - step 4's text amended in TASK.md to what was
    delivered (lint pointer added, move-instruction kept, with the
    reasoning); tick-against-the-literal-step gets its x2 bump in the
    retro.
- [x] R1.3 (NIT) tatr/SKILL.md:28 - ledger findings print a literal
  `ledger` in the id slot, and an unreadable ledger path is itself a
  finding (exit 1), both undocumented. Suggested: append a sentence.
  - Response: fixed - tatr SKILL.md's check bullet now covers the ledger id
    slot, the unreadable-ledger finding, and the annotated-count exemption
    in the same breath.

Reviewer verification notes: all documented rules, flags, exit codes and
formats tested against the real binary with mktemp fixtures (one finding
per rule kind, both closed-not-approved variants, strict on/off, ledger
bare/annotated/in-section counts, per-ID and error paths); compound's gate
confirmed coherent - default check passes before RETRO.md exists, so
flow's land-then-compound ordering does not deadlock; suite-wide
consistency read against review/work/plan/sprout skills and the ledger;
both DoD proofs pass; dogfood exit-0 claim reproduced.

## Round 2

- VERDICT: APPROVE
- REVIEWER: out-of-context (same fresh-context subagent, resumed)

All three findings verified resolved against the text at 6f4915b: the
bare-counts convention now lives in both reader-facing places and names the
exact evading form (re-verified against the binary: annotated (x4, ...) is
exempt, bare (x4) flags); the repo's own annotated x3 entry is consistent
(genuinely promoted); no contradiction with the format example, step 6, or
compound's target-marker style (markers sit outside the count parens, so
compound-style entries stay lintable). Step 4's amended text records the
deviation. Reviewer's operational note: this APPROVE line itself restores
the tree's clean tatr check exit.
