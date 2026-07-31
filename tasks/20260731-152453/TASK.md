# Work skill: worktree-path rule must cover tatr record commands

- STATUS: OPEN
- PRIORITY: 65
- TAGS: skills,flow,docs
- KIND: TASK
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT

## Story

As a flow user, I want the work skill's worktree-path rule to name `tatr`
record commands alongside edits and git calls, so lifecycle transitions are
not run against the main checkout once a worktree exists.

## Notes

- Found by task 20260731-150849 review round 1 (R1.1, MAJOR): three
  `tatr flow` calls ran in the main checkout, leaving master with an
  uncommitted `FLOW STEP: REVIEWING` and the branch record stale at `PLANNED`.
- Current prose: "Shell cwd does not persist: use absolute worktree paths for
  every edit/git call." `tatr` is neither word.
- `tatr -r <root>` is the explicit form, mirroring `git -C`.
- `work/SKILL.md` body is at 281 of 400 words, so the rule can be widened in
  place rather than moved to a reference.
