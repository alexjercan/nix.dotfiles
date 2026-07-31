# Review: Make fresh-session handoff a flow contract

- TASK: 20260731-174352
- BRANCH: feat/fresh-session-handoff

## Round 1

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

- [x] R1.1 (MAJOR) home/modules/agents/skills/work/delegation.md:49 - the
  checkpoint handoff is a two-hop load. `work/SKILL.md` routes "at a context
  checkpoint" to `delegation.md`, whose `## Checkpointing for a fresh session`
  is a 3-line stub that then sends the reader to `flow/resume.md`. An agent at
  a checkpoint reads ~990 words across two references to run one protocol.
  `check.sh`'s `reference-too-deep` rule only fires when the nested target is
  in the SAME skill directory, so a cross-skill nested load passes the gate
  while violating the rule `README.md` states. Fix: drop the section, drop the
  checkpoint condition from work's pointer, and let work's always-loaded Rules
  line name `flow/resume.md`.
  - Response: fixed as directed. `## Checkpointing for a fresh session` is
    gone; work's pointer condition is now "under context pressure, or a
    bounded Step a subagent could own"; and the Rules line that already owns
    the 120K/150K trigger now ends "`flow/resume.md` owns the handoff", so the
    checkpoint path is one hop from an always-loaded line. `delegation.md` was
    retitled "Delegating a bounded Step" and its intro no longer promises a
    checkpoint protocol it does not hold. One prose cross-reference remains in
    that intro for orientation; it forces no load, because work's Rules line
    reaches `resume.md` directly.
- [x] R1.2 (MINOR) home/modules/agents/skills/work/delegation.md:51 - the
  surviving stub restates rules `flow/resume.md` also states, in a second
  vocabulary - the same restatement defect the close-out claims this diff
  removed. It removed the large half and left a small one.
  - Response: fixed, subsumed by R1.1. The observation is correct: the
    close-out claimed a de-duplication it had only half done.
- [x] R1.3 (MINOR) home/modules/agents/skills/flow/resume.md:16 - the handoff
  introduces a new flow output path with no output contract. `flow/SKILL.md`
  caps output and enumerates only `SPIKED`/`PLANNED`/`DONE`/`GOAL DONE`; a
  checkpoint is none of those.
  - Response: fixed; §0 now states that a checkpoint is not terminal, so the
    handoff report carries no status line.
- [x] R1.4 (MINOR) home/modules/agents/skills/flow/SKILL.md:50 - "at a context
  checkpoint" appeared verbatim in two `## Load on demand` tables pointing at
  two different files, with nothing telling a reader which wins.
  - Response: fixed by R1.1 - work's condition is now "under context
    pressure", so the two conditions no longer collide.
- [x] R1.5 (NIT) tasks/20260731-174352/DECISION.md:26 - "costs 3 words and is
  paid for by 4 words of tightening" does not re-derive; the three tightenings
  are -1 each, so the trade is net zero and the body is 300 before and after,
  not 299.
  - Response: confirmed by re-deriving it against
    `git show master:.../flow/SKILL.md` with check.sh's own body extractor -
    300 before, 300 after, three one-word cuts against a three-word addition.
    DECISION.md now says net zero and names it as not a saving. The wrong
    arithmetic had also reached the user-facing option text.

- Process signal: `reference-too-deep` cannot see cross-skill nested loads, so
  R1.1 passed conformance on a technicality. The gate proves shape within one
  skill directory only. Worth a gate widening in a follow-up task, not this
  one.

Verified by the reviewer: both `cmd:` proofs red on master and green on the
branch; all five conjuncts sabotaged individually and restored; 20260731-174348's
two proofs still passing after the `delegation.md` edit; `check.sh` clean,
`sprout-test.sh` 14/14, `tatr check` 0, `--ledger` 0, `nix flake check` 0;
every close-out budget number re-derived and matching; the whole skills tree
swept for checkpoint/handoff/clear/compact language.

Pending user checks (do not block a verdict): the `manual:` DoD proof -
checkpoint a WORKING fixture Story, clear the session, paste the emitted
prompt, and confirm the new session selects the correct branch and next
unticked Step.

## Round 2

- REVIEWER: out-of-context
- VERDICT: APPROVE

All five round-1 findings verified fixed by the round-1 reviewer, which
re-derived every budget itself and sabotage-tested all five of this task's
conjuncts plus all seven of 20260731-174348's `delegation.md` conjuncts, to
prove the section deletion took nothing those proofs depend on. It confirmed
no rule was lost rather than relocated: "must never claim it can" survives in
`flow/resume.md`, and the tick rule survives both there and in
`work/SKILL.md`'s always-loaded body.

On the one judgement call I flagged: the reviewer accepted the residual prose
cross-reference in `delegation.md`'s intro as a scope boundary rather than a
routed load, since no condition sends a checkpointing agent into that file any
more, and `review/rounds.md` already names `work/delegation.md` the same
descriptive way.

- Process signal: `reference-too-deep` cannot see cross-skill nested loads.
  The reviewer asked for a follow-up task rather than a signal buried in one
  branch's REVIEW.md, on the grounds that cross-skill pointers already exist
  in the tree so the gap is demonstrated, not hypothetical. Seeded as
  20260731-204959.
- Process signal: `flow/resume.md` is at 597/600, so two surfaces in the suite
  are now effectively frozen, not one. Recorded in the close-out Reflection.
