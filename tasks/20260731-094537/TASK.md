# Widen absence-proof grep guidance to exclude prose about the removal

- STATUS: OPEN
- PRIORITY: 55
- TAGS: feature, skills, lessons
- KIND: TASK
- FLOW STEP: PLANNED
- PLAN STATUS: APPROVED

## Story

As a plan author, I want absence-proving greps to exclude prose ABOUT a
removal as well as the task records, so a proof that a mechanism is gone is
not defeated by the comment explaining that it is gone.

## Steps

- [ ] Rewrite `## Absence proofs must exclude the records` (line 38) in
      `home/modules/agents/skills/plan/proofs.md` per DECISION.md: retitle it
      so it covers prose about the code, state BOTH halves of the self-match
      (the record quoting the string, and the comment or NOTE the same diff
      writes about the removal), and replace the two-line example block with
      the pipe-free form
      ``(cmd: `grep -rn --exclude-dir=tasks -E '^[^#]*oldname' .`)``.
- [ ] In the same section, state that `^[^#]*` is language-specific (`^[^/]*`
      for `//` languages) and WHY it is one command rather than a `| grep -v`
      tail, so a reader does not reinvent the form DECISION.md rejected. The
      `## Proofs must be able to fail` no-pipe rule at line 50 stays as is;
      this section must not contradict it.
- [ ] Re-point anything citing the old heading by name:
      `grep -rn "exclude the records" home/modules/agents/skills`.
- [ ] Fold the ledger entry: delete the `## Pending promotions` entry
      (LESSONS.md line 195) and rewrite the `## Process lessons` entry (line
      142) so ONE entry remains, carrying an applied marker and dropping its
      "see Pending promotions" pointer. `promotion-stalled` fires on an entry
      outside Pending with no marker, so `(x6, PROMOTED 2026-07-31 -> plan
      skill DoD guidance)` is the shape to keep (verified at tatr.c:6571).
- [ ] Run the gates below, plus `nix flake check --no-build`.

## Definition of Done

- The section carries the pipe-free worked command, comment-exclusion pattern
  included (cmd: ``grep -n "\^\[\^#\]\*" home/modules/agents/skills/plan/proofs.md``).
- Its heading no longer scopes the rule to the records alone
  (cmd: `grep -n "^## Absence proofs" home/modules/agents/skills/plan/proofs.md`).
- One ledger entry for the slug remains and it is outside Pending promotions
  (cmd: `grep -c dod-grep-excludes-task-records LESSONS.md` prints 1).
- The skill suite still conforms, budgets included
  (cmd: `bash home/modules/agents/skills/check.sh`).
- Repository conformance passes with the ledger folded
  (cmd: `tatr check --ledger LESSONS.md`).

## Notes

- Promoted from the `dod-grep-excludes-task-records` (x6) ledger lesson,
  disposition PROMOTE recorded 2026-07-31. This WIDENS the existing
  2026-07-20 promotion rather than adding a new rule.
- Cost two grep rewrites in 20260730-190929; see DECISION.md for the two
  false reds and why the ledger's own `| grep -vE` form was rejected.
- Proofs run against base at plan time: the `^[^#]*` grep is red (rc=1, the
  guidance is not there yet), the heading grep prints line 38, and
  `grep -c` prints 2 - so each one moves for the right reason.
- The `test: dod_grep_excludes_comments` proof this record used to carry was
  dropped: it assumed `home/modules/agents/skills/fixtures/`, deleted in
  20260730-154955. check.sh has no per-file content rule to extend, so the
  DoD is pinned on greps over the reference file itself.
- The pattern was dry-run in a scratch tree (see DECISION.md); it excludes
  both a leading `#` comment and a trailing one, honours `--exclude-dir`, and
  returns rc=1 with no output when the mechanism is genuinely gone.
- proofs.md is 508 of its 1000-word `reference-budget`, so roughly six added
  lines are affordable.
- The change is prose in a reference file; it still takes the normal
  out-of-context round-1 review before landing.
