# Review: Write the sabotage-at-plan-time rule into the proofs reference

- TASK: 20260731-125123
- BRANCH: docs/sabotage-proofs-rule

## Round 1

- REVIEWER: out-of-context
- VERDICT: APPROVE

No BLOCKER or MAJOR findings. The two below are the implementer's discretion;
R1.1 is being taken because the doc-surface rule owes it to this same task.

- [x] R1.1 (MINOR) home/modules/agents/skills/lessons/ledger.md:68 - the file
  says the promoting task "records the outcome through `tatr ledger`, which is
  what turns `PROMOTE` into the applied `PROMOTED <date> -> <target>` and moves
  the entry back to its section". This branch is the live counterexample:
  `tatr ledger -D` takes only PROMOTE|DEFER|RETIRE|ABSORBED, so the fold in
  this diff was a hand edit. Rewrite the clause to say the last step hand-edits
  the entry out of `## Pending promotions`, rewriting the count to the applied
  marker, and that `tatr ledger` records dispositions only. Note `ledger.md` is
  at 977 of its 1000-word budget, so the replacement must be word-neutral.
  - Response: rewritten at `ledger.md:67-70` - the last step now "hand-edits
    the entry out of `## Pending promotions`, rewriting `PROMOTE` to the
    applied `PROMOTED <date> -> <target>`", followed by "`tatr ledger` records
    dispositions only and has no flag for that transition". `wc -w` 977 -> 980,
    inside budget; `check.sh` and `nix flake check` re-run clean. Swept the
    skills tree and AGENTS.md for the same claim elsewhere: no other hits.
- [x] R1.2 (NIT) tasks/20260731-125123/TASK.md:57 - DoD proofs 6 (`check.sh`)
  and 7 (`tatr check --ledger`) are green on master, so read alone they are the
  failure mode this task documents. The Notes paragraph says so, but the DoD
  shows seven equal criteria. Append "(regression guard, green on base; pinned
  by the budget mutation in Notes)" to proof 6 and "(regression guard, green on
  base)" to proof 7.
  - Response: both DoD bullets now carry the annotation inline, placed BEFORE
    the `(cmd: ...)` group so the proof text tatr parses is unchanged -
    `tatr proofs` still lists 7, and `tatr check` is clean.

### Verification

The round-1 reviewer ran the seven proofs and the four canonical checks from
the worktree root and mutation-tested every proof in a scratch mirror: each
reddens ALONE, proofs 1-5 are red on master and 6-7 green. Its numbers match
the close-out table, and `wc -w proofs.md` = 943 as recorded.

The in-session pass re-derived R1.1 independently: `ledger.md:67-71` carries
the claim, `tatr ledger --help` lists only the four dispositions, and
`wc -w ledger.md` = 977. It also re-ran `check.sh` (clean),
`sprout-test.sh` (14/14), `tatr check --ledger` (0) and `nix flake check`
(3 checks passed).

No `manual:` DoD items are open on this task.

## Round 2

- REVIEWER: out-of-context
- VERDICT: APPROVE

The round-1 reviewer verified both fixes against `f0bb916..eabea78` and
returned RESOLVED for each; its confirmation is what ticks R1.1 and R1.2 above.
For R1.1 it re-checked the replacement against `tatr ledger --help`, confirmed
`wc -w ledger.md` = 980 under the 1000-word budget, and swept the skills tree,
`AGENTS.md` and `README.md`: the remaining `tatr ledger` mentions are all about
recording a disposition and stay true. For R1.2 it diffed `tatr proofs` against
its round-1 capture and found the proof text byte-identical, still 7 proofs.
All 7 proofs and the four canonical checks exited 0.

- [x] R2.1 (NIT) home/modules/agents/skills/lessons/ledger.md:71 - the R1.1
  rewrite left the paragraph unreflowed: line 71 ended `no flag for that
  transition. A` with an orphaned article, so a matcher on "A PROMOTE whose
  task never lands" would miss across the wrap. Rewrap so that sentence starts
  a line.
  - Response: rewrapped; `A PROMOTE whose task never lands is therefore still
    visible as pending work,` is now one line. `check.sh`, `sprout-test.sh`,
    `tatr check --ledger` and `nix flake check` re-run clean, and all 7 proofs
    still exit 0. Ticked on the in-session pass, which is the round's own
    reviewer for this one-line reflow.
