# Write the sabotage-at-plan-time rule into the proofs reference

- STATUS: OPEN
- PRIORITY: 55
- TAGS: skills,lessons,docs
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

As a plan author, I want the sabotage-at-plan-time rule written where proofs
are written, so a DoD ships with proofs that can fail rather than proofs that
merely run.

## Steps

- [ ] Decide with the user where the rule lands: a clause inside
      `## Proofs must be able to fail` in
      `home/modules/agents/skills/plan/proofs.md`, or its own short section.
      The file is 790 of its 1000-word `reference-budget`, so the wording has
      to earn its space; prefer the clause unless the section reads as two
      rules.
- [ ] State the rule: before a proof is accepted into a Definition of Done,
      delete or invert the clause it pins and confirm it goes red ALONE, with
      the other proofs green. Size is no exemption - a one-line `grep -c` is
      the shape that has failed twice.
- [ ] State the two failure modes the three recurrences produced, because each
      is invisible to running the proof: a proof matching MORE than the clause
      it pins (green after either half is deleted), and a proof already green
      on the base branch (it pins something the change does not alter).
- [ ] Sabotage this task's own DoD proofs at plan time, before any edit, and
      record which mutation reddens each one.
- [ ] Record the promotion's completion: move the ledger entry back out of
      `## Pending promotions` carrying its applied marker.

## Definition of Done

- The proofs reference states the sabotage rule, both failure modes, and that
  the timing is plan rather than work (manual: read the new clause in
  `home/modules/agents/skills/plan/proofs.md`). Planning replaces this with
  `cmd:` proofs once the wording is chosen, and sabotages each one first.
- The skill suite still conforms, budgets included
  (cmd: `bash home/modules/agents/skills/check.sh`).
- Repository conformance passes with the ledger entry folded
  (cmd: `tatr check --ledger LESSONS.md`).

## Notes

- Promoted from the `write-the-sabotage-first` (x3) ledger lesson, disposition
  PROMOTE recorded 2026-07-31 by the user. Recurrences: 20260730-142533,
  20260730-155003, 20260731-094537.
- No tool can sabotage a proof for the author, so the promotion order lands
  this at skill prose rather than at a checker rule. `check.sh` has no per-file
  content rule to extend.
- 20260731-094537 is the worked example on both failure modes: its first
  pattern proof matched the code fence AND the prose sentence, so deleting
  either alone left it green; its heading proof matched the pre-change heading
  and was therefore green on master before any work started, surviving plan,
  work and two review rounds.
- Do not restate the whole lesson in the file. One rule, the two failure modes,
  and the timing (plan, not work) is the payload.
