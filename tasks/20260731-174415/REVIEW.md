# Review: Turn review and context overruns into planning lessons

- TASK: 20260731-174415
- BRANCH: feat/compound-planning-lessons

## Round 1

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

- [x] R1.1 (MAJOR) home/modules/agents/skills/compound/SKILL.md:46 - the new
  closing line "REVIEW owns findings, TASK owns change facts, RETRO owns
  one-off process analysis, LESSONS owns recurring general lessons" restates,
  under a second name, rules the same file already states: line 8 ("RETRO
  records process. TASK records the change; REVIEW records findings"), step
  5's "Keep one-offs only in RETRO", and "A recurring pattern belongs in the
  ledger". `duplicated-paragraph` is verbatim-only and cannot see it. Fix:
  delete the line and fold the only genuinely new clause into line 8.
  - Response: fixed as directed. Line 8 is now "RETRO records one-off process,
    LESSONS recurring lessons. TASK records the change; REVIEW records
    findings" - the LESSONS half was the only new information - and the
    closing line is gone. This is the third time in this Epic that a
    restatement was shipped by the same hand that wrote the lesson against it;
    the Step-5 text I duplicated was two screens above what I was writing.
- [x] R1.2 (MINOR) home/modules/agents/skills/compound/SKILL.md:49 - the
  pre-existing rule "Do not duplicate prose across records..." previously
  closed `## Workflow`; the new `## Diagnose` heading reparented it so it
  reads as a Diagnose-only rule. Fix: move it back above `## Diagnose`.
  - Response: fixed; the paragraph is back above the new heading, so its scope
    is file-wide again. A heading inserted below a paragraph silently changes
    that paragraph's scope - nothing in the diff touched those lines.
- [x] R1.3 (MINOR) home/modules/agents/skills/compound/SKILL.md:39 - "the
  from-scratch challenge, or the cold-reader one" names two plan-time
  questions, but only from-scratch is defined at plan time. "Cold reader"
  appears in `review/dimensions.md` (review time) and `plan/decision.md`
  (rationale capture), so a retro agent has to guess which is meant.
  - Response: fixed; the bullet now points at both sources by name - the
    from-scratch challenge in `plan`, and the cold-reader rationale test in
    `plan/decision.md`.
- [x] R1.4 (MINOR) tasks/20260731-174415/TASK.md:41 - the rewrite tightened
  DoD 2 but left DoD 1 with two OR-shaped conjuncts.
  `rg -q 'plan.*review|review.*plan'` would pass on any sentence containing
  "plan" before "review", so it does not guard the churn rule - the exact
  defect the close-out names.
  - Response: fixed; DoD 1's conjuncts are now the literal text they guard,
    `a missed split that` and
    `which plan-time question would have prevented`. All five conjuncts across
    both proofs were then sabotaged individually and each turned only its own
    proof red. I had tightened DoD 2 for this reason and left DoD 1 alone,
    which is the same half-done fix pattern round 1 caught in 20260731-174352.

- Process signal: two of the six planned DoD proofs were unfalsifiable and had
  to be rewritten during implementation. CORRECTED in round 2 by the reviewer:
  `plan/proofs.md` ALREADY mandates sabotaging each proof at plan time and
  already rejects a proof that is green at base, so this was non-compliance
  with an existing rule, not a missing rule. That strengthens the case for a
  gate over more prose - which is the disposition already recorded for
  `baseline-dod-proofs` (PROMOTE -> 20260731-202400, a tool).

Verified by the reviewer: the full diff; all six Steps re-read literally; all
six originally-planned conjuncts confirmed red on master via
`git archive master`; every final conjunct sabotage-tested; `check.sh` 0,
`sprout-test.sh` 14/14, `tatr check` 0, `--ledger` 0, `nix flake check` 0;
both close-out word counts re-derived exactly (369/400, and 211 on master);
`review/rounds.md`, `work/delegation.md`, `plan/SKILL.md`, `lessons/` and
`flow/` swept for contradictions, with the `Process signal:` producer and the
120K/150K checkpoint confirmed consumed rather than redefined. The reviewer
judged the DoD-2 rewrite a legitimate tightening rather than a dodge, and the
`diagnose.md` rejection the right call.

Pending user checks (do not block a verdict): the `manual:` DoD proof - a
fresh reviewer confirms REVIEW owns findings, TASK owns change facts, RETRO
owns one-off process analysis, and LESSONS owns recurring general lessons.

## Round 2

- REVIEWER: out-of-context
- VERDICT: APPROVE

All four round-1 findings confirmed fixed. The reviewer re-derived the body
count (361/400, master still 211), ran both DoD proofs, and sabotaged all five
conjuncts individually while checking BOTH proofs each time, confirming each
sabotage turned only its own proof red. It also diffed the pre-fix commit line
by line to confirm no other paragraph was reparented by the `## Diagnose`
heading, and checked that narrowing the header from "records process" to
"records one-off process" lost no rule - the recurring half is now explicit in
the same sentence and agrees with step 5, step 4 and `lessons/SKILL.md`.

- [x] R2.1 (NIT) tasks/20260731-174415/TASK.md:97 - the rewritten Evidence
  line wraps at 84 chars while the rest of the record wraps at 80.
  - Response: fixed; re-wrapped. The only remaining over-80 lines in the
    record are the DoD `cmd:` proofs, which must stay on one line.

The reviewer also ran an Epic-wide restatement sweep, reading all 27 skill
files rather than grepping, since this is the Epic's last Story. It found
three genuine paraphrase-restatements, none introduced by this branch:
the 120K/150K thresholds stated in both `work/SKILL.md` and
`work/delegation.md`; `work/verify.md` restating `work/bug.md`'s
commit-before-sabotage rule; and `work/verify.md`'s "Sync base" restating
`flow/landing.md`. Per `review/SKILL.md` these are pre-existing repository
problems and belong in a task, not this verdict: seeded as 20260731-205300.
It explicitly cleared the two `lanes.md` files, the subagent packet bounds,
and the size rule stated once per phase as sanctioned rather than duplication.

Pending user checks (do not block APPROVE): the `manual:` DoD proof - a fresh
reviewer confirms REVIEW owns findings, TASK owns change facts, RETRO owns
one-off process analysis, and LESSONS owns recurring general lessons.
