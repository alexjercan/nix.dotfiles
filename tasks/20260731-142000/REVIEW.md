# Review: Make avoidable complexity block review approval

- TASK: 20260731-142000
- BRANCH: refactor/complexity-blocks-approval

## Round 1

- REVIEWER: out-of-context
- VERDICT: APPROVE

No BLOCKER or MAJOR finding. The five MINOR/NIT findings below were all fixed
in this round before the verdict was recorded.

- [x] R1.1 (MINOR) home/modules/agents/skills/compound/SKILL.md:16 - `rounds.md`
  introduces the `Process signal:` prefix "so compound can read it", but no
  compound rule names the token; a producer with no declared consumer is the
  structure the diff's own Design bar rejects. Add the counterpart clause to
  compound, or drop the claim.
  - Response: the consumer is Story 20260731-174415, which depends on this
    task and owns `compound/SKILL.md`; editing compound here would put two
    Stories in one file. Kept the prefix, reworded the clause to name the
    consumer as owed rather than present.
- [x] R1.2 (MINOR) home/modules/agents/skills/review/rounds.md:39 - the round-1
  handoff contract says the out-of-context reviewer returns "findings only ...
  No narrative", which does not authorize the new `Process signal:` bullet.
  Amend so the two neighboring rules agree.
  - Response: fixed; the RETURNS clause now names `Process signal:` bullets
    alongside the findings. This is the neighboring-contract sweep the same
    diff promotes, catching its own omission.
- [x] R1.3 (MINOR) tasks/20260731-142000/TASK.md:94 - the close-out reports
  "`SKILL.md` 336/400", but 336 is `wc -w` of the whole file; `check.sh`
  measures the BODY against `BUDGET_PHASE_BODY`, and that value is 306.
  - Response: confirmed by independently re-deriving the body count with the
    same frontmatter-stripping awk `check.sh` uses; corrected to 306/400.
- [x] R1.4 (NIT) home/modules/agents/skills/review/SKILL.md:13 - the edit left a
  ragged wrap ("... are the spec. Run" / "checks from ..."). Reflow to full
  width.
  - Response: fixed; the numbered item is reflowed.
- [x] R1.5 (NIT) tasks/20260731-142000/TASK.md:46 - the first DoD proof's
  `rg -q 'applicable.*AGENTS.md' home/modules/agents/skills/review` is
  satisfied by `dimensions.md` alone, so it stays green if the `SKILL.md`
  workflow-1 clause is reverted. Scope that clause to its file.
  - Response: fixed, and the cause was worse than reported - the phrase spanned
    a line break, so the proof never matched `SKILL.md` at all. Reflowing for
    R1.4 put it on one line; the proof now carries a `SKILL.md`-scoped
    conjunct so reverting either file turns it red.

- [ ] R1.6 (NIT) home/modules/agents/skills/review/rounds.md:41 - the R1.2 edit
  reintroduced the ragged wrap R1.4 removed. Reflow lines 39-43.
  - Response: fixed. Raised by the reviewer after it recorded APPROVE, so the
    box stays unticked - the fix is in-session and unconfirmed by the round's
    reviewer. A NIT does not block the verdict.
- [ ] R1.7 (NIT) home/modules/agents/skills/review/lanes.md:19 - the parallel
  lane return contract still says "findings by severity plus verified/skipped
  items" and did not get the R1.2 treatment.
  - Response: fixed; the lane RETURNS clause now names `Process signal:`
    bullets too. Same unticked rationale as R1.6. This is the third neighboring
    contract the promoted sweep caught in its own diff.

Verified by the reviewer: the full diff against every ticked Step's literal
text; all five `cmd:` proofs run in the worktree and confirmed absent on
master; two proofs sabotage-tested red and restored; `check.sh` clean,
`sprout-test.sh` 14/14, `tatr check` and `--ledger` 0, `nix flake check`
passed; budgets re-derived independently. The in-session pass re-derived the
R1.3 word count and the R1.5 line-break cause, and reran the full suite after
the fixes.

Pending user checks (do not block APPROVE): the `manual:` DoD proof - a fresh
reviewer applies the revised dimensions to one tangled diff and one direct
diff and confirms only the first receives a MAJOR structural finding.
