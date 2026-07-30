# Retro: Refactor flow skills for bounded context and concise output

- TASK: 20260730-142533
- BRANCH: refactor/flow-skills-bounded-context
- REVIEW ROUNDS: 3

## What went well

- Asking about the test-harness fork BEFORE building it. The DoD named four
  tests describing agent runtime behavior that nothing here can observe, and
  the two candidate artifacts were mutually exclusive as a `cmd:` proof. One
  question and a DECISION.md turned a guess into a recorded choice, and the
  reviewer independently agreed the tradeoff was fairly stated.
- The out-of-context reviewer earned its keep three times over: 20 findings in
  round 1, 7 in round 2, and every MAJOR was reproduced by the reviewer
  breaking it again rather than reading the diff. Two of those - a hardcoded
  skill list and a vacuous self-test branch - were invisible from inside the
  implementing session precisely because the gate was green.
- Sabotage-verifying the nix checks in a real `git init` copy. The reviewer hit
  the trap first (a `cp -r` worktree keeps a `.git` FILE pointing at the
  original gitdir, so nix reads the unsabotaged tree and the drv hash never
  changes) and recorded it, which saved the second and third rounds.

## What went wrong

- **The gate was written before anything that could break it.** `check.sh`
  went green on its first run and I treated that as evidence. It was not: R1.1
  (a hardcoded skill list, so a new skill was never checked at all) and R1.3
  (a self-test claiming 21 rules proven when 21 cases covered 20 of 26) both
  survive a green run by construction. Root cause: the rules were written and
  then observed to pass, which is exactly the after-the-fact test the work
  skill forbids for code, applied to a checker.
- **R2.1 is the same mistake one level deeper.** The self-test added to prove
  the gate could fail contained a branch that itself could not fail: the
  undeclared-rule check bumped `failures` after the only place `failures` was
  read. A vacuous check inside the anti-vacuity harness.
- **The refactor deleted prose by SECTION, not by RULE.** "Remove the
  Relationship sections" and "cut to 800 words" were applied to blocks of
  text, and four rules that happened to live inside those blocks went with
  them: ask before working a dirty main tree, the non-sprout fallback, spike's
  same-second `tatr new` rule, and spike's `## Fix record`. None was owned by
  a tool, so none had licence to go. All four were reviewer finds.
- **Coverage-shaped claims were asserted rather than computed.** "21 rules
  proven able to fail" and "runs in CI-shaped contexts" were both written from
  intent. The first was arithmetically wrong; the second described a script
  nothing ran automatically.
- **Documented numbers drifted from enforced ones twice.** The description
  budget moved 40 -> 30 in code but not in the README table, and the close-out
  kept the pre-review word counts. Both are the kind of precise-looking figure
  a later session trusts without recomputing.

## What to improve next time

- Write one sabotage case per rule BEFORE the rule. Every rule in this gate is
  a test-first candidate, and doing it in that order would have made R1.1,
  R1.3 and R2.1 impossible rather than findable.
- When a change claims coverage or completeness, COMPUTE it from the artifact
  and fail on the gap. `check.sh --rules` plus a computed diff replaced a
  hand-written count; the hand-written count was wrong the day it was written.
- Refactor prose by extracting every imperative from the old file first, then
  checking each one is present, moved, or deliberately retired. Cutting by
  section silently drops rules that happen to share a heading with filler.
- Make every documented number derivable, or re-derive it at close-out. A
  budget in a table and a budget in a constant are two sources of truth.

## Action items

- [x] Lessons ledger updated: `write-the-sabotage-first`,
      `compute-coverage-dont-claim-it`, `refactor-by-rule-not-by-section`.
- [x] `check.sh --rules` plus computed coverage replaces the asserted count.
- [x] tatr 20260731-010900: decide whether the live-agent behavior pass is
      worth automating, once the user has run it by hand (DECISION.md's
      rejected alternative). Created at p20 - deliberately low, since a one-off
      manual confirmation may be the right answer forever.
