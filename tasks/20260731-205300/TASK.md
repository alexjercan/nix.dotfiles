# Give three duplicated skill rules a single owner

- STATUS: OPEN
- PRIORITY: 60
- TAGS: skills, docs, duplication
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

As a skill reader, I want each rule stated once, so two surfaces cannot drift
apart and a reader cannot be left guessing which copy is current.

## Steps

- [ ] `work/SKILL.md` and `work/delegation.md` both state the 120K/150K
      thresholds AND the token-unavailable fallback. Decide the split: the
      always-loaded body needs only the trigger that makes the reference load,
      and the reference should own the numbers. Note that 20260731-174348's
      DoD proofs currently pin both tokens in BOTH files, so this task must
      supersede those proofs rather than silently break them.
- [ ] `work/verify.md` restates `work/bug.md`'s commit-before-sabotage rule
      under a second name; `bug.md` carries the rationale and `verify.md` adds
      nothing. Delete the copy and point at the owner.
- [ ] `work/verify.md`'s "Sync base" restates `flow/landing.md` steps 1 and 3,
      including the same `merge-base --is-ancestor` gate. Give it one owner.
- [ ] Re-run every affected task's DoD proofs and reconcile any that pinned
      the deleted copy.
- [ ] Extend the Docs sweep in `home/modules/agents/skills/review/dimensions.md`
      to ask BOTH questions: does anything now CONTRADICT this, and does
      anything now RESTATE it under a second name. Name why the second question
      needs a human: `duplicated-paragraph` is verbatim-only and cannot see a
      paraphrase.

## Definition of Done

- Each of the three rules is stated in exactly one file, with any second
  mention being a pointer rather than a restatement (manual: fresh reviewer
  reads the four files and confirms one owner each).
- No previously-passing DoD proof is left red, or the superseded ones are
  explicitly reconciled in their own records (cmd:
  `bash home/modules/agents/skills/check.sh && tatr check`).
- The review Docs sweep asks for restatement, not only contradiction (cmd:
  `rg -q 'RESTATE' home/modules/agents/skills/review/dimensions.md`).
- Repository gates pass (cmd:
  `bash home/modules/scripts/sprout-test.sh && nix flake check`).

## Notes

- Seeded by 20260731-174415 round 2. The reviewer read all 27 skill files
  (rather than grepping) as an Epic-wide restatement sweep and found exactly
  these three; none was introduced by that branch, so per `review/SKILL.md`
  ("review the diff, not pre-existing repository problems; create tasks for
  those") they belong here.
- The reviewer explicitly cleared several near-misses as sanctioned rather
  than duplication: the two `lanes.md` files, the subagent packet bounds in
  `review/rounds.md` vs `work/delegation.md`, and the size rule stated once
  per phase in `plan`, `review` and `compound` - each is that phase's own
  version of the rule, not a copy.
- The threshold duplication came from Epic 20260731-174333 itself
  (20260731-174348), so this is that Epic's debt, not pre-existing drift.
- Not a child of Epic 20260731-174333: its Done Means are satisfied, and this
  is cleanup the Epic's own reviews surfaced.
- Promotion target for `sweep-for-restatement-not-just-contradiction` (x3,
  PROMOTE). No tool can see a paraphrase and no template owns prose, so the
  promotion lands as the review-sweep rule above, alongside the three
  restatements that lesson found.
