# Write the sabotage-at-plan-time rule into the proofs reference

- STATUS: OPEN
- PRIORITY: 55
- TAGS: skills, lessons, docs
- KIND: TASK
- FLOW STEP: PLANNED
- PLAN STATUS: APPROVED

## Story

As a plan author, I want the sabotage-at-plan-time rule written where proofs
are written, so a DoD ships with proofs that can fail rather than proofs that
merely run.

## Steps

- [x] Decide with the user where the rule lands: a clause inside
      `## Proofs must be able to fail` in
      `home/modules/agents/skills/plan/proofs.md`, or its own short section.
      Answer: its own section, immediately after `## Proofs must be able to
      fail`. See `DECISION.md`.
- [x] Sabotage every DoD proof below at plan time, before any edit, and record
      which mutation reddens each one. Results in Notes.
- [ ] Add `## Sabotage every proof before accepting it` to
      `home/modules/agents/skills/plan/proofs.md`, between
      `## Proofs must be able to fail` and `## Example`. It states the rule
      (delete or invert the clause a proof pins, confirm it goes red ALONE
      with the others green), the timing (PLAN, not work), that size is no
      exemption, and the two failure modes as two bullets: a proof matching
      MORE than the clause it pins, and a proof already green on the base
      branch. Wording is drafted and budget-checked at 153 words; do not
      restate the rest of the lesson.
- [ ] Fold the ledger entry: move `write-the-sabotage-first` out of
      `## Pending promotions` in `LESSONS.md` into `## Process lessons`,
      rewriting its count annotation to the applied marker
      `(x3, PROMOTED 2026-07-31 -> plan skill proofs reference)` and keeping
      its sentence and the three recurrence ids intact. `tatr ledger` has no
      disposition for this transition (`-D` takes only
      PROMOTE|DEFER|RETIRE|ABSORBED), so the move is a hand edit - confirm
      that before reaching for the CLI.
- [ ] Run the four conformance commands from the repo root and record their
      output in the task record.

## Definition of Done

- The reference states the rule, in a section of its own
  (cmd: `grep -n 'goes red ALONE' home/modules/agents/skills/plan/proofs.md`).
- It states the timing as plan rather than work
  (cmd: `grep -n 'at PLAN time, not at' home/modules/agents/skills/plan/proofs.md`).
- It states the first failure mode, a proof matching more than its clause
  (cmd: `grep -n 'matches MORE than the clause it pins' home/modules/agents/skills/plan/proofs.md`).
- It states the second failure mode, a proof already green on the base branch
  (cmd: `grep -n 'already green on the base branch' home/modules/agents/skills/plan/proofs.md`).
- The ledger entry sits outside `## Pending promotions` carrying its applied
  marker (cmd: `awk '/write-the-sabotage-first.*PROMOTED 2026-07-31/{print NR": "$0; f=1} /^## Pending promotions/{exit !f} END{exit !f}' LESSONS.md`).
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
- Budget: the drafted section is 153 words, taking `plan/proofs.md` from 790 to
  943 of the 1000-word `reference-budget`. 57 words of headroom, so the wording
  cannot grow much in work or review.

### Plan-time sabotage of these proofs

Run on the base branch against a scratch copy of the drafted file, before any
edit to the repo. Every proof was RED on base first - none was already green -
and each mutation reddened its own proof ALONE, the other five staying green.

| Proof | Mutation that reddens it |
| --- | --- |
| `goes red ALONE` | delete that clause from the opening paragraph |
| `at PLAN time, not at` | delete the timing sentence |
| `matches MORE than the clause it pins` | delete the first failure-mode bullet |
| `already green on the base branch` | delete the second failure-mode bullet |
| ledger `awk` | leave the applied marker on the entry but keep it under `## Pending promotions` - the marker alone is not the fold |
| `check.sh` | pad the new section past 1000 words: `reference-budget: 1123 words > 1000` |

`tatr check --ledger LESSONS.md` and `check.sh` are both green on master, so
they are regression guards, not criteria - which is why `check.sh` is pinned by
its budget mutation above and the ledger fold has its own `awk` proof rather
than leaning on `tatr check`.
