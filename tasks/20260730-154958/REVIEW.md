# Review: Add conditional parallel planning and review lanes

- TASK: 20260730-154958
- BRANCH: feature/parallel-lanes

## Round 1

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

- [x] R1.1 (MAJOR) home/modules/agents/skills/review/lanes.md:31 - the behavior
  lane is told to run each proof from `tatr proofs <id>`, while Resources
  (line 80) says anything mutating build output, a lock file, a result symlink
  or a shared cache is run ONCE by the primary reviewer. A lane cannot satisfy
  both when a proof is a build - this task's own proof 7 is
  `nix flake check --no-build`. Qualify the lane to run the read-only proofs
  and read the primary's result for the rest, or name proofs explicitly as the
  exception in Resources.
  - Response: fixed - the behavior lane now runs only the read-only proofs and judges the primary's result for anything that builds, writes a lock file or touches a shared cache (review/lanes.md:30).

- [x] R1.2 (MINOR) tasks/20260730-154958/TASK.md:108 - the DoD claims the
  ordinary-work disclosure cases "prove the `lanes.md` pointer condition does
  not fire on ordinary work", and Step 3 repeats it as "proves ordinary work
  cannot reach the lanes". A `forbids` case only asserts the condition contains
  none of the words `ordinary routine trivial`. Re-derived in session:
  appending ", or any planning task at all" to plan's condition leaves
  `--fixture parallel_lane_selection` and the whole gate green. Reword both
  lines to what the mechanism does - the condition never names ordinary or
  routine work - and record the limit in DECISION.md's Consequences.
  - Response: fixed - the DoD criterion and Step 3 now say what the pair does (a word guard on the condition), and DECISION.md's Consequences records that a condition widened in other words stays green. Re-derived the appended-clause case in session before rewording.

- [x] R1.3 (MINOR) home/modules/agents/skills/review/lanes.md:55 - "the primary
  reviewer" is used seven times and never bound to anything in
  `review/SKILL.md`, which speaks of the out-of-context reviewer and the
  in-session pass. Its duties here are the in-session pass's. Bind it once at
  line 55: "the primary reviewer - the in-session pass of step 2 - owns the
  round".
  - Response: fixed - bound at the head of ## Aggregation: "the primary reviewer - the in-session pass the review skill's step 2 describes - owns the round".

- [x] R1.4 (MINOR) tasks/20260730-154958/TASK.md:120 - the DoD criterion says
  "writers get distinct sprout worktrees", which neither lanes file states:
  `review/lanes.md:86` says the implementer works in the task's own sprout
  worktree, singular, and `plan/lanes.md:90` says one worktree and one
  implementer. The fixture passes only because `sprout worktree` is a substring
  of the singular phrase. Reword the criterion to the rule that shipped.
  - Response: fixed - the criterion now reads "read-only lanes share a checkout and never sprout, writing stays in the task's own sprout worktree", which is the rule both files state.

- [x] R1.5 (MINOR) home/modules/agents/skills/review/lanes.md:43 -
  `rounds.md:29` says each lane is held to "exactly the bounds below", and
  those bounds list what the reviewer receives "and nothing else"; line 43 then
  adds "plus the one lane it owns". Change rounds.md to "held to the bounds
  below, plus the lane assignment" so the two files agree.
  - Response: fixed - rounds.md now reads "held to the bounds below plus its own lane assignment".

- [x] R1.6 (NIT) tasks/20260730-154958/TASK.md:154 - the Notes record
  "`parallel_lane_selection` now reports 6 cases"; it reports 15, as Step 1
  says. Fix the number.
  - Response: fixed - 15, matching what --fixture parallel_lane_selection reports.

- [x] R1.7 (NIT) home/modules/agents/skills/review/lanes.md:59 - "a lane that
  cannot write to the branch also cannot be checked by the branch" does not
  parse. The point is that a lane's claim arrives with no artifact the primary
  can inspect. Reword.
  - Response: fixed - reworded to "a lane returns a claim and no artifact to inspect".

Verification, by the out-of-context reviewer and re-derived in session: the
gate is clean (9 skills, 179 description words); `--self-test` reports 39
sabotage cases and 32 of 32 rules; all five new `--fixture` proofs pass
(15/1/1/1/2 cases); `tatr check --ledger LESSONS.md` is clean; `nix flake
check --no-build` passes. Every `loads:` disclosure token and every content
`requires:` token was deleted or mutated in turn and each turned its own proof
red, so no new case is unfalsifiable. The two `forbids:` cases are
non-vacuous but weak, which is R1.2. No new `fail` slug; `RULES` and
`selftest.sh` are untouched. The reference graph stays one level deep and
`rounds.md` names the lanes file in prose only. The `manual:` DoD item was
correctly left pending, not self-ticked.

## Round 2

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

Round 1: R1.1 through R1.7 all verified resolved, each against the cited lines
rather than the Response text. The R1.2 re-derivation was reproduced
independently. Their boxes are ticked above.

- [x] R2.1 (MAJOR) home/modules/agents/skills/review/lanes.md:34 - the R1.1 fix
  tells the behavior lane that a building proof "belongs to the primary under
  Resources below, and the lane judges the primary's result", but nothing hands
  the lane that result: the RECEIVES list in `rounds.md:33` is closed ("and
  nothing else"), and Resources (line 84) lets the primary run those checks
  "before or after the lanes report", so on the "after" ordering the artifact
  does not exist when the lane needs it. Drop the judging clause: the lane
  skips those proofs and records them as not verified, and the primary runs and
  judges them during aggregation.
  - Response: fixed - the behavior lane now skips a building or cache-touching proof and reports it as not verified; the primary runs and judges it during aggregation. No result is handed across the closed handoff (review/lanes.md:33).

- [x] R2.2 (MINOR) home/modules/agents/skills/review/lanes.md:56 - the R1.3
  rebinding wrapped so the line begins `- owns the round.`, which markdown
  renders as a list item, orphaning the clause as a bullet under the
  `## Aggregation` heading. Reflow so the closing dash is not at line start.
  - Response: fixed - reflowed to "The round is owned by the primary reviewer, which is the in-session pass the review skill's step 2 describes", so no line starts with a dash (review/lanes.md:55).

## Round 3

- REVIEWER: out-of-context
- VERDICT: APPROVE

Round 2: R2.1 and R2.2 both verified resolved against the cited lines, and
their boxes are ticked above. The two findings below are MINOR and NIT, so they
are the implementer's discretion and do not block. Both were fixed after this
round was issued; the Response lines record what landed, and the boxes stay
unticked because this round's reviewer has not seen the fixes.

- [ ] R3.1 (MINOR) home/modules/agents/skills/review/lanes.md:35 - the R2.1 fix
  pins the deferred proof to "the primary runs and judges it during
  aggregation", but Resources still said those checks run "before or after the
  lanes report", and the Aggregation list had no step that runs a proof. Either
  make Resources say "after", or add the run as an Aggregation step.
  - Response: fixed both ways - Aggregation gained step 1 "Runs the proofs the
    behavior lane skipped, and judges them" (the rest renumbered 2-5), and
    Resources now reads "serially, after the lanes report".

- [ ] R3.2 (NIT) home/modules/agents/skills/review/lanes.md:58 - the R2.2
  reflow made the lead-in passive, so the numbered list's bare verbs dangle
  from "The round" rather than from the reviewer performing them.
  - Response: fixed - "The primary reviewer, the in-session pass the review
    skill's step 2 describes, owns the round."

Pending USER checks, not resolved by this APPROVE:

- (manual) 20260730-154958 DoD item 8: run one lane-selecting review and read
  the round, confirming the lanes stay inside their stated caps and the round
  reads as one deduplicated review rather than three concatenated ones.
