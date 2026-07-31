# Review: Add explicit flow dispatch table

- TASK: 20260731-142934
- BRANCH: feat/flow-dispatch-table

## Round 1

- REVIEWER: out-of-context
- VERDICT: REQUEST_CHANGES

- [x] R1.1 (MAJOR) home/modules/agents/skills/flow/SKILL.md:15 - the legend
  "`--to` marks a non-default edge" contradicts `tatr/lifecycle.md`, which
  makes PLANNING -> PLANNED and PLANNED -> WORKING the DEFAULT next edges of a
  bare `tatr flow <id>`; only the REVIEWING -> WORKING fix loop is non-default.
  As written the table labels two default edges as non-default, so a cold
  reader infers the wrong transition graph, and Step 4 ("remove conflicting
  route prose") is ticked over the conflict. Reword the legend so `--to` names
  the explicit target rather than a non-default one, and say that the review
  fix loop is the only backward edge.
  - Response: fixed. The legend now reads "Transitions run `tatr flow <id>`;
    `--to` spells the target. Only the fix loop reverses." I reproduced the
    finding before accepting it: in a scratch repository a bare `tatr flow`
    moved PLANNING -> PLANNED (writing `PLAN STATUS: APPROVED`) and then
    PLANNED -> WORKING, so both were indeed defaults. The cells keep `--to` on
    PLANNED, WORKING and the fix loop, now consistent with the legend rather
    than contradicting it, and the redundant "to " prefix was dropped from the
    five rows that named a plain successor.

- [x] R1.2 (MINOR) home/modules/agents/skills/flow/SKILL.md:48 - the `epic.md`
  pointer condition dropped `version`, which master's pointer carried and which
  the ledger lesson `one-request-one-task` names in its trigger set. A request
  phrased "cut version 2.1" no longer matches a stated condition. Restore
  `version` to the pointer condition.
  - Response: fixed. `version` is back in the `epic.md` pointer condition. The
    same audit caught a second word I had traded for budget inside this round
    and then restored: the `landing.md` condition briefly lost its leading
    "landing".

- [x] R1.3 (MINOR) home/modules/agents/skills/flow/SKILL.md:30 - the
  "Landed, default branch" row ends `GOAL DONE <id>` unconditionally while the
  DONE row already ends `DONE <id>`, so a single-task flow that lands and then
  finishes names two status lines; `epic.md` reserves `GOAL DONE <epic-id>` for
  the container close, and master's prose reported only `DONE <id>` here.
  Qualify the row so `GOAL DONE <id>` is the goal/epic case.
  - Response: fixed. The finish row now ends "goals end `GOAL DONE <id>`", so
    a single-task flow reports only the DONE row's `DONE <id>`.

- [x] R1.4 (NIT) home/modules/agents/skills/flow/SKILL.md:43 - "a last status
  line" became "a status line", dropping the requirement that it be last, which
  is what makes the line findable. Restore "a last status line".
  - Response: fixed. `## Output` reads "a last status line" again.

- [x] R1.5 (NIT) home/modules/agents/skills/flow/SKILL.md:15 - "`tatr` owns
  legality; this table routing" elides the verb across a non-parallel clause
  and reads as an error rather than compression. Use "`tatr` owns legality;
  this table owns routing."
  - Response: fixed as suggested.

Verification by the out-of-context reviewer:

- Both DoD greps red on master, green on the branch, confirmed by extracting
  master's SKILL.md directly.
- `check.sh` clean (9 skills, 22 rules, 179 description words); the flow body
  is exactly 300 of 300 words, so no rule may be added without a trim.
- `sprout-test.sh` 14 passed 0 failed; `tatr check --ledger LESSONS.md` clean;
  `nix flake check` all checks passed, built rather than `--no-build`.
- The table covers all eight lifecycle states, the fix loop, landing and
  finish, and every phase skill flow dispatches; rows match the `review` and
  `compound` output contracts.
- Compression-at-risk rules survive elsewhere: the container rule in
  `epic.md`, pending-promotion settlement in `lessons/SKILL.md`, and `## Stop`
  and the authority-of-task-prose rule verbatim.
- `resume.md`'s deleted table is subsumed by the Route table; its three
  retained cautions add what the table lacks. No stale references to the
  numbered Route in README.md, AGENTS.md or sibling skills.

Re-derived in session, per the round-1 contract: R1.1's load-bearing claim was
reproduced in a scratch repository, not read off the documentation. A task
built to PLANNING and then advanced with a BARE `tatr flow <id>` moves
PLANNING -> PLANNED and writes `PLAN STATUS: APPROVED`, and a second bare call
moves PLANNED -> WORKING. Both edges are therefore defaults, and the legend's
claim about them is false. The check suite above was re-run in session with
the same results.

Pending user checks (open `manual:` proofs, not blocking):

- "The table covers every tatr state and preserves the guarded review fix loop
  (manual: fresh reviewer compares the table with `tatr/lifecycle.md` and all
  dispatched phase contracts)." The out-of-context reviewer performed that
  comparison and R1.1 is its result; signing the item off remains the user's.

Implementer's re-verification after the round-1 fixes: `check.sh` clean, with
the flow body back at 300 of 300 words after the added words were paid for by
per-cell trims; both DoD greps green and each conjunct still falsified
independently (rewriting the header row reddens only the first, deleting the
spike row only the second); `sprout-test.sh` 14 passed 0 failed;
`tatr check --ledger LESSONS.md` clean; `nix flake check` all checks passed.

## Round 2

- REVIEWER: out-of-context
- VERDICT: APPROVE

- [ ] R2.1 (NIT) home/modules/agents/skills/flow/SKILL.md:10 - the round-1 fix
  traded master's "else `tatr new` one task" for "else `tatr new` a task". The
  `one-request-one-task` ledger lesson's numeric constraint then survives in
  the body only via line 8's "One tatr task", and the container qualifier lives
  solely in the `epic.md` pointer condition. TASK.md's Close-out also says the
  budget "came from per-cell trims", which is imprecise: two of those trims are
  intro and legend prose, not cells. Restore "one task" on line 10 and correct
  the Close-out sentence.
  - Response: fixed both. "one task" is restored - it cost nothing, since "a
    task" and "one task" are the same two words, so the suggested funding from
    line 30 was not needed and "goals end `GOAL DONE <id>`" stands. The
    Close-out now says the four words were paid for by tightening the tagline,
    the legend and the post-table prose as well as two cells.

Round-1 findings R1.1 through R1.5 were each confirmed fixed by the
out-of-context round-2 reviewer against the `f671d48..4361e1a` diff, and their
boxes are ticked on that confirmation. R1.1's load-bearing claim was
re-derived a second time, independently, in a throwaway repository: a bare
`tatr flow` walks BACKLOG -> UNDERSTANDING -> PLANNING -> PLANNED (writing
`PLAN STATUS: APPROVED`) -> WORKING -> REVIEWING, so the reworded legend is
true and the original was not.

Verification, re-run in session after the R2.1 fix: `check.sh` clean (9 skills,
22 rules, 179 description words), flow body at 300 of 300; both DoD greps
green; `sprout-test.sh` 14 passed 0 failed; `tatr check --ledger LESSONS.md`
clean; `nix flake check` all checks passed. The round-2 reviewer confirmed no
rule present on master's `flow/SKILL.md` was retired by compression, and that
dropping the "to " prefix from five rows loses no meaning under the
"Transition / result" header.

Pending user check, not blocking APPROVE: the `manual:` DoD item asking a
fresh reviewer to compare the table with `tatr/lifecycle.md` and the dispatched
phase contracts. Two out-of-context reviewers performed that comparison across
rounds 1 and 2; signing it off remains the user's.
