# Widen absence-proof grep guidance to exclude prose about the removal

- STATUS: OPEN
- PRIORITY: 55
- TAGS: feature,skills,lessons
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

As a plan author, I want absence-proving greps to exclude prose ABOUT a
removal as well as the task records, so a proof that a mechanism is gone is
not defeated by the comment explaining that it is gone.

## Steps

- [ ] Widen the `## Absence proofs must exclude the records` guidance in
      `home/modules/agents/skills/plan/proofs.md`: a diff that removes a
      mechanism usually also writes prose naming it, so the grep excludes
      comment lines as well as `tasks/`.
- [ ] Give the guidance a worked command form (e.g. adding
      `| grep -vE ":[0-9]+: *#"`) so the rule is copyable, not just stated.
- [ ] Add or extend a content fixture asserting the widened rule is stated,
      and confirm it is red before the edit.
- [ ] Record the promotion's completion through `tatr ledger` per
      shrink-on-absorb.

## Definition of Done

- The proofs reference states that absence greps exclude comment lines as well
  as `tasks/` (test: `dod_grep_excludes_comments`).
- The skill suite still conforms
  (cmd: `bash home/modules/agents/skills/check.sh`).

## Notes

- Promoted from the `dod-grep-excludes-task-records` (x6) ledger lesson,
  disposition PROMOTE recorded 2026-07-31. This WIDENS the existing
  2026-07-20 promotion rather than adding a new rule.
- Cost two grep rewrites in 20260730-190929.
- The change is prose in a reference file; it still takes the normal
  out-of-context round-1 review before landing.
