# Promote refactor-by-rule-not-by-section into skill prose

- STATUS: OPEN
- PRIORITY: 60
- TAGS: skills,lessons,docs
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

As a skill author trimming prose to a word budget, I want a stated
inventory-then-diff rule, so a size-driven rewrite cannot silently retire a
rule word that only a reviewer would notice.

## Steps

- [ ] Decide the owning skill: `work` (the phase that performs the rewrite) or
      `plan` (the phase that sizes it). Record the choice and why in
      DECISION.md.
- [ ] Add one rule to that SKILL.md: before a size-driven rewrite, list the
      imperative words the text carries; after it, diff that list, not the
      prose. Every dropped word is retained, moved, or explicitly retired.
- [ ] Pay for the added words within the owning skill's body budget without
      retiring another rule - the failure this rule exists to prevent.
- [ ] Fold `refactor-by-rule-not-by-section` into the promoted rule per
      `lessons/ledger.md`, leaving the ledger entry marked PROMOTED.
- [ ] Run the skill gate, sprout tests, ledger check, and flake checks.

## Definition of Done

- The owning skill states the inventory-then-diff rule and the retained,
  moved, or explicitly retired disposition for each dropped word
  (cmd: TODO at plan time - write the grep, then sabotage it by deleting the
  rule and confirm it reddens).
- The skill suite stays conformant and no existing rule was dropped to fund
  the new one (cmd: `bash home/modules/agents/skills/check.sh`).
- Repository checks pass (cmd: `bash home/modules/scripts/sprout-test.sh &&
  tatr check --ledger LESSONS.md && nix flake check`).

## Notes

- Promoted from `refactor-by-rule-not-by-section` (x3) on 2026-07-31 by the
  user's disposition. Occurrences: 20260730-142533, 20260731-133122,
  20260731-142934.
- Promotion order audit found no tool or template owner: nothing can
  distinguish a rule word from a filler word, so skill prose is the only
  candidate.
- The budget squeeze is the whole difficulty. If the owning skill cannot
  afford the rule, that is a finding about the budget, not a reason to write
  a vaguer rule.
- `measure-the-empty-structure` is the sibling lesson from the same task and
  may be worth citing in the rule's wording.
