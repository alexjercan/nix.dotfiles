# Write the sabotage-at-plan-time rule into the proofs reference

- STATUS: CLOSED
- PRIORITY: 55
- TAGS: skills, lessons, docs

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
- [x] Add `## Sabotage every proof before accepting it` to
      `home/modules/agents/skills/plan/proofs.md`, between
      `## Proofs must be able to fail` and `## Example`. It states the rule
      (delete or invert the clause a proof pins, confirm it goes red ALONE
      with the others green), the timing (PLAN, not work), that size is no
      exemption, and the two failure modes as two bullets: a proof matching
      MORE than the clause it pins, and a proof already green on the base
      branch. Wording is drafted and budget-checked at 153 words; do not
      restate the rest of the lesson.
- [x] Fold the ledger entry: move `write-the-sabotage-first` out of
      `## Pending promotions` in `LESSONS.md` into `## Process lessons`,
      rewriting its count annotation to the applied marker
      `(x3, PROMOTED 2026-07-31 -> plan skill proofs reference)` and keeping
      its sentence and the three recurrence ids intact. `tatr ledger` has no
      disposition for this transition (`-D` takes only
      PROMOTE|DEFER|RETIRE|ABSORBED), so the move is a hand edit - confirm
      that before reaching for the CLI.
- [x] Run the four conformance commands from the repo root and record their
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
- The skill suite still conforms, budgets included - a regression guard, green
  on base, pinned by the budget mutation recorded in Notes
  (cmd: `bash home/modules/agents/skills/check.sh`).
- Repository conformance passes with the ledger entry folded - a regression
  guard, green on base; the fold itself is pinned by the `awk` proof above
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

## Close-out

**What changed.** `plan/proofs.md` gains
`## Sabotage every proof before accepting it` between
`## Proofs must be able to fail` and `## Example`: 14 lines stating the
mutation rule, the PLAN-not-work timing, "size is no exemption", and the two
failure modes as one bullet each. `LESSONS.md` moves
`write-the-sabotage-first` out of `## Pending promotions` into
`## Process lessons` carrying `(x3, PROMOTED 2026-07-31 -> plan skill proofs
reference)`; `## Pending promotions` is now empty and `tatr check --ledger`
accepts that. `proofs.md` ends at 943 of 1000 words.

**Why this shape.** The two adjacent sections now read as rule and gate: the
first says a proof must be ABLE to fail, the second says prove it by making it
fail. See DECISION.md for the section-vs-clause fork.

**Verification.** Every proof was watched RED in this worktree before the edit
(all five change-pinning ones exited 1 on the untouched files), then green
after. Full suite from the worktree root, run bare:

| Check | Result |
| --- | --- |
| `nix flake check` | all checks passed (3 checks) |
| `bash home/modules/agents/skills/check.sh` | clean (9 skills, 22 rules, 179 description words) |
| `bash home/modules/scripts/sprout-test.sh` | passed: 14, failed: 0 |
| `tatr check --ledger LESSONS.md` | exit 0 |
| DoD proofs 1-7 | all exit 0 |

**Doc-surface sweep.** `grep -rn "Proofs must be able to fail\|proofs.md"` over
`*.md`/`*.nix`/`*.sh` outside `tasks/` returns two hits: the heading itself and
`plan/SKILL.md:85`, a generic `-> proofs.md` pointer that needs no change. No
file enumerates the reference's sections, so nothing else went stale.

**Difficulties.** The two conformance commands the original DoD carried
(`check.sh`, `tatr check --ledger`) are both green on master, so as written
they were the very failure mode this task documents. Planning replaced them:
`check.sh` is now pinned by a demonstrated budget-overflow mutation
(`reference-budget: 1123 words > 1000`) and the ledger fold got its own `awk`
proof, which stays red when the applied marker is present but the entry has
not left `## Pending promotions`. The `tatr ledger` CLI turned out to have no
disposition for PROMOTE -> PROMOTED (`-D` takes only
PROMOTE|DEFER|RETIRE|ABSORBED), confirmed against `tatr ledger --help` before
the hand edit, even though `lessons/ledger.md` describes the transition as
happening "through `tatr ledger`". Recorded for the retro rather than fixed
here - it is a CLI gap, not this task's diff.

**Self-reflection.** The task asked its own DoD to be sabotaged at plan time,
and doing so is what caught the two base-green proofs. The rule paid for
itself before it was written.
