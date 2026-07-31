# Widen reference-too-deep to cross-skill pointer chains

- STATUS: OPEN
- PRIORITY: 65
- TAGS: skills, check, conformance
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

As a skill author, I want the conformance gate to catch a reference that sends
the reader on to another skill's reference, so a two-hop load cannot pass
`check.sh` the way one did in 20260731-174352.

## Steps

- [ ] Reproduce the gap: a reference in skill A naming a reference file in
      skill B currently passes `reference-too-deep`, because the rule only
      tests the nested target within the SAME skill directory.
- [ ] Decide what counts as a violation. A pointer that ROUTES a load is one;
      a descriptive cross-reference naming another skill's file is not, and
      `review/rounds.md` and `work/delegation.md` both legitimately do the
      latter today. Record the distinction in DECISION.md - it is the whole
      difficulty of this task.
- [ ] Implement the widened rule, and add a case asserting the gate stays
      CLEAN on the existing legitimate cross-references
      (`test-the-quiet-direction`).
- [ ] Update `home/modules/agents/skills/README.md` if the widened rule
      changes what the stated "one level deep" convention means in practice.

## Definition of Done

- The gate fails a fixture where skill A's reference routes a load into skill
  B's reference (test: a sabotage case in the check suite).
- The gate stays clean on the descriptive cross-references already in the tree
  (test: the same suite, asserting exit 0 on the unmodified skills dir).
- The repository gates still pass (cmd:
  `bash home/modules/agents/skills/check.sh && nix flake check`).

## Notes

- Seeded by 20260731-174352 round 2. The round-1 reviewer found that the
  checkpoint handoff had become a two-hop load - `work/SKILL.md` routed to
  `work/delegation.md`, which forwarded to `flow/resume.md` - and that
  `check.sh` could not see it. The diff was fixed; the GATE was not.
- The reviewer argued for a task rather than leaving the observation in one
  branch's REVIEW.md, because cross-skill pointers already exist in the tree,
  so the gap is demonstrated rather than hypothetical, and a signal in a
  review file is not a surface anyone re-reads.
- Not a child of Epic 20260731-174333: the Epic's Done Means are about the
  skills' content, not the gate's coverage.
