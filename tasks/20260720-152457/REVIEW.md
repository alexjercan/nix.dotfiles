# Review: DoD items name their proof (test/cmd/manual) across plan, work, review, flow

- TASK: 20260720-152457
- BRANCH: feat/dod-proof-notation

## Round 1

- VERDICT: APPROVE
- REVIEWER: out-of-context

Fresh subagent, no sight of the implementing session. Diffed
`master...feat/dod-proof-notation`, ran both DoD `cmd:` greps (both pass),
and checked notation coherence across the five skills. In-session supplement
re-verified the load-bearing claims: both greps pass, marker spelling is
uniform, and the manual-doesn't-block rule is consistent across plan/review/flow.

Verdict APPROVE with two MINOR findings (one real issue) and a NIT, all
addressed in this round.

Open `manual:` DoD items for this task (pending user checks, batched at Finish):
- the notation reads well in this flow's own task files.

- [x] R1.1 (MINOR) plan/SKILL.md notation - `manual:` is documented as a
  trailing `(manual: ...)` marker but both examples lead with a bare
  `manual:`; the example authors copy is inconsistent with the stated rule.
  - Response: Reconciled by blessing the leading form. The notation now says
    that when the whole criterion IS the judgement, lead the item with a bare
    `manual: <...>` rather than trailing it (criterion and proof are one). The
    leading form is what the dogfooded task DoDs already use, so this aligns
    the rule to practice instead of churning every example.
- [x] R1.2 (MINOR) tasks/20260720-152457/TASK.md:37 - the task's own manual
  DoD uses the bare leading form; pick one convention and make plan agree.
  - Response: Same fix as R1.1 - the leading form is now the blessed shape for
    pure-judgement items, so this DoD conforms. Also backticked this task's
    two `cmd:` proofs so the `{plan,work,...}` brace-glob renders literally
    (per user feedback mid-round).
- [x] R1.3 (NIT) flow/SKILL.md step 3.7 - a dangling mid-clause line wrap
  ("and continue with the" / "next task.").
  - Response: Rewrapped to a single clean line.

## Round 1 addendum - user feedback (mid-round)

The user asked that command/test proofs be wrapped in backticks so markdown
does not mangle globs/quotes/stars. Made backticks part of the prescribed
notation (plan skill: "put the test name or command in backticks"), fixed the
plan example DoD, the flow GOAL.md format block, and this task's own DoD to
use them. The `test:`/`cmd:`/`manual:` grep tokens are unaffected (still
present in the raw text), so the DoD proofs still pass.
