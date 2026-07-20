# Goal: flow-suite v2 - reviews, goal artifact, landing tool, DoD proofs, artifact linting

- DATE: 20260720
- UMBRELLA TASK: 20260720-152427
- LANDING SCOPE: squash-merge each task to master in nix.dotfiles, no push;
  the tatr work lands on master in ~/personal/tatr, no push. Flake input
  `tatr` keeps lagging until the user pushes tatr and bumps flake.lock.

## Goal

Implement the 7 improvements accepted from the 2026-07-20 unbiased review of
the flow skill suite (spike/plan/work/review/compound/lessons/flow), in the
skills' source repo (nix.dotfiles) and the tatr repo.

## Done means

1. review skill: an out-of-context reviewer produces round 1 by default for
   substantive branches (cmd: grep -n "out-of-context" home/modules/agents/skills/review/SKILL.md;
   manual: dogfooded by this flow's own reviews).
2. flow skill: step 1 creates an umbrella task + GOAL.md, Finish verifies
   against it and closes it (cmd: grep -n "GOAL.md" home/modules/agents/skills/flow/SKILL.md).
3. `sprout land` performs the guarded squash-merge landing as one command
   (cmd: bash home/modules/scripts/sprout-test.sh; the flow skill's landing
   prose shrinks to use it).
4. DoD items name their proof (test/cmd/manual) in the plan, work, review and
   flow skills; manual items batch to a user checkpoint at Finish
   (cmd: grep -rn "manual:" home/modules/agents/skills/{plan,work,review,flow}/SKILL.md).
5. `tatr check` lints task artifacts (cmd: nix develop -c ./checker.sh in
   ~/personal/tatr) and the skills reference it (cmd: grep -rn "tatr check"
   home/modules/agents/skills).
6. lessons/compound skills carry ledger lifecycle rules: RETIRED marker,
   tool > template > skill-text promotion order, shrink-on-absorb
   (cmd: grep -n "RETIRED" home/modules/agents/skills/lessons/SKILL.md).
7. work skill carries the docs-sync rule: a change is not done until every
   doc surface it invalidates is updated in the same task
   (cmd: grep -n "doc surface" home/modules/agents/skills/work/SKILL.md).

Overall: nix evaluation green on master (cmd: nix flake check --no-build) and
the tatr suite green in ~/personal/tatr (cmd: nix develop -c ./checker.sh).

## Tasks

Updated as tasks land (one line per land, like a spike's Fix record).

- [x] 20260720-152433 (p100, nix.dotfiles) sprout land command + skill/doc shrink
      landed acb0ecc; 2 review rounds (out-of-context R1 found an unfailable
      test, MAJOR); 14 integration tests; landed via sprout land itself
- [x] 20260720-152438 (p95, nix.dotfiles) review skill: out-of-context round-1 default
      landed 24aec4f; 2 rounds (R1 caught a docs-only carve-out loophole,
      MAJOR); REVIEWER field now in the skill's round format
- [x] 20260720-152451 (p90, nix.dotfiles) flow skill: umbrella task + GOAL.md
      landed 158f23e; 1 review round (out-of-context APPROVE, 2 NITs, 1 fixed);
      GOAL.md format block + step 1/plan/3.7/Finish wiring; tatr+plan cross-refs
- [x] 20260720-152503 (p90, ~/personal/tatr) tatr check artifact linter
      landed 5239772 (tatr 0.3.0); 2 rounds (R1: MAJOR whitespace hole in
      STATUS validation + 7 more, all reproduced); 60/60 tests, memcheck
      clean; tatr's own backlog normalized and lint-clean
- [x] 20260720-152457 (p85, nix.dotfiles) DoD proof notation across skills
      landed 98944e9; 1 review round (out-of-context APPROVE, 2 MINOR + 1 NIT,
      all fixed); test:/cmd:/manual: proofs across plan/work/review/flow/tatr;
      proofs backticked per user feedback; leading bare manual: blessed
- [ ] 20260720-152508 (p75, nix.dotfiles) wire tatr check into the skills
- [ ] 20260720-152514 (p70, nix.dotfiles) ledger lifecycle rules
- [ ] 20260720-152519 (p65, nix.dotfiles) work skill docs-sync rule

## Manual acceptance (batched for the user at Finish)

Accumulates `manual:` DoD items as tasks land.

- (pending) 20260720-152433: user sees a later task of this flow landed via
  sprout land
- (pending) 20260720-152438: user sees the REVIEWER field in committed
  REVIEW.md files of this flow
- (pending) 20260720-152451: this flow's GOAL.md matches the format the
  skill prescribes
- (pending) 20260720-152457: the proof notation reads well in this flow's
  task files
