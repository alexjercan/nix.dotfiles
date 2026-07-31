# Make fresh-session handoff a flow contract

- STATUS: OPEN
- PRIORITY: 80
- TAGS: skills,flow,context,docs
- KIND: STORY
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT
- PARENT: 20260731-174333
- DEPENDS ON: 20260731-174348

## Story

As a flow user, I want context exhaustion to produce a durable checkpoint and a
minimal fresh-session prompt, so I can `/clear` and resume the exact task state
without copying a lossy conversation summary.

## Steps

- [ ] Update `home/modules/agents/skills/flow/SKILL.md` and `flow/resume.md` so a
      worker checkpoint from 20260731-174348 is a first-class flow handoff, not
      an exceptional failure.
- [ ] State the actor boundary: the agent records and verifies durable state,
      then asks the user to run `/clear`; it cannot invoke `/clear` or
      `/compact` as a tool.
- [ ] Emit a copy-pastable fresh-session prompt whose essential payload is
      `/flow <id>`. Include extra text only when uncommitted or external state
      cannot be discovered from tatr, git, and sprout.
- [ ] On resume, use `tatr show <id>`, `tatr context <id> --phase resume`, the
      worktree diff, literal Steps, and latest review state. Read only the next
      phase packet; do not reconstruct or trust the previous conversation.
- [ ] Preserve lifecycle transitions, output caps, and the rule that disk
      records are authoritative. Run all canonical checks.

## Definition of Done

- Flow explicitly separates agent checkpointing from user-owned `/clear` and
  emits `/flow <id>` as the normal fresh-session prompt (cmd: `rg -q '/clear' home/modules/agents/skills/flow && rg -q '/flow <id>' home/modules/agents/skills/flow`).
- Resume names structured task state, the phase packet, worktree diff, and
  literal Steps as its recovery inputs (cmd: `rg -q 'tatr show <id>' home/modules/agents/skills/flow/resume.md && rg -q 'worktree diff' home/modules/agents/skills/flow/resume.md && rg -q 'literal.*Steps' home/modules/agents/skills/flow/resume.md`).
- A fresh session resumes without a bespoke chat summary (manual: checkpoint a
  WORKING fixture Story, clear the session, paste the emitted prompt, and
  confirm the new session selects the correct branch and next unticked Step).
- The skill suite remains conformant and within all measured budgets (cmd:
  `rg -q '/clear' home/modules/agents/skills/flow && bash home/modules/agents/skills/check.sh`).
- Repository checks pass (cmd: `rg -q '/clear' home/modules/agents/skills/flow && tatr check && tatr check --ledger LESSONS.md && nix flake check`).

## Notes

- `flow/resume.md` already makes disk state authoritative and phase-selective.
  Extend that contract; do not introduce a second handoff document.
- Exact token thresholds belong to work. Flow owns checkpoint-to-resume routing
  across all triggers.
