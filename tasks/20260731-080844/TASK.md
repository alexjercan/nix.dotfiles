# Reconcile the documented bare manual: proof form with tatr check

- STATUS: OPEN
- PRIORITY: 30
- TAGS: docs,skills,flow
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

As a plan author, I want the documented `manual:` proof form to be the form
`tatr check` accepts, so a DoD written from the skill does not fail the lint.

## Steps

- [ ] Decide the direction: either `plan/proofs.md` drops the bare leading
      `manual:` form and its example uses `(manual: ...)`, or tatr's
      `artifact_next_proof` (tatr.c) also accepts a bare leading marker. The
      skill is the cheaper surface and the parenthesized form is already what
      every landed task uses; prefer it unless the user wants the parser
      widened.
- [ ] Apply the chosen change, including the `## Example` block, so the rule
      and its example agree.
- [ ] Re-run the gate.

## Definition of Done

- `plan/proofs.md` and `tatr check` agree on the `manual:` form, example
  included (cmd: `bash home/modules/agents/skills/check.sh`).
- A scratch task whose only DoD item is written in the documented form lints
  clean (cmd: `tatr check --ledger LESSONS.md`).

## Notes

- Found during 20260730-154958 planning: a DoD item written as the documented
  bare `- manual: ...` was rejected as `bad-proof-syntax`. tatr's
  `artifact_next_proof` only scans for `(<kind>: ...)` groups.
- The `rule-and-example-must-agree` lesson applies: proofs.md's own example
  models the rejected form.
