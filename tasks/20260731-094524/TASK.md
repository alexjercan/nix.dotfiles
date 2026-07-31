# Render close-out diff stats from a tool instead of retyping them

- STATUS: OPEN
- PRIORITY: 60
- TAGS: feature,tatr,lessons
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

As a record author, I want the diff's numbers rendered by a tool rather than
retyped, so a work report or close-out cannot cite a triple no diff produces.

## Steps

- [ ] Add `tatr stat <id> [--since <base>]` to the tatr repo, emitting the
      `git diff --shortstat` line for the task's branch.
- [ ] Decide the fallback: if the verb is more tool than it is worth, ship the
      close-out template carrying the COMMAND instead of its result, and say so
      here rather than leaving this step unticked.
- [ ] Update the work and compound close-out guidance to cite the generated
      output.
- [ ] Record the absorption with `tatr ledger -s counts-come-from-the-diff -D
      ABSORBED -T <target>` once both repositories land, per shrink-on-absorb.

## Definition of Done

- A close-out's diff numbers come from generated output, not a retyped number
  (manual: the user confirms one close-out cites the tool's line verbatim).
- The lessons ledger entry carries its applied marker
  (cmd: `tatr check --ledger LESSONS.md`).

## Notes

- Promoted from the `counts-come-from-the-diff` (x3) ledger lesson,
  disposition PROMOTE recorded 2026-07-31.
- The tool itself lives in the OTHER repository (/home/alex/personal/tatr);
  this task is the nix.dotfiles-side tracker, because the ledger this
  promotion annotates is checked against this repository's tasks/ tree.
- Recurrences: 20260720-171843, 20260720-171836, 20260730-142540 (R1.6, R2.1).
- Promotion order says tool > template; the fallback is the template form.
