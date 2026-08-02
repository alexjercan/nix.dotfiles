# Make fresh-session handoff a flow contract

- PRIORITY: 80
- TAGS: skills, flow, context, docs
- KIND: STORY
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE
- PARENT: 20260731-174333
- DEPENDS ON: 20260731-174348

## Story

As a flow user, I want context exhaustion to produce a durable checkpoint and a
minimal fresh-session prompt, so I can `/clear` and resume the exact task state
without copying a lossy conversation summary.

## Steps

- [x] Update `home/modules/agents/skills/flow/SKILL.md` and `flow/resume.md` so a
      worker checkpoint from 20260731-174348 is a first-class flow handoff, not
      an exceptional failure.
- [x] State the actor boundary: the agent records and verifies durable state,
      then asks the user to run `/clear`; it cannot invoke `/clear` or
      `/compact` as a tool.
- [x] Emit a copy-pastable fresh-session prompt whose essential payload is
      `/flow <id>`. Include extra text only when uncommitted or external state
      cannot be discovered from tatr, git, and sprout.
- [x] On resume, use `tatr show <id>`, `tatr context <id> --phase resume`, the
      worktree diff, literal Steps, and latest review state. Read only the next
      phase packet; do not reconstruct or trust the previous conversation.
- [x] Preserve lifecycle transitions, output caps, and the rule that disk
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

## Close-out

What/why: a context checkpoint is now routed, not improvised.
`flow/SKILL.md`'s `## Load on demand` condition for `resume.md` became "at a
context checkpoint, or resuming after `/clear` or context loss", so the
outgoing handoff has a route where before only the incoming resume did.
`flow/resume.md` was retitled "Checkpointing and resuming a flow" and gained
`## 0. Hand off before you lose the context`: commit an atomic green step,
record the completed Step, commit and check results, and the next Step; emit
`/flow <id>` as the whole fresh-session payload; add a line only for state
that `tatr`, `git` and `sprout` cannot reveal. The actor boundary is explicit
- the agent records and verifies, then ASKS the user to run `/clear`, and can
never invoke `/clear` or `/compact` itself. Section 3 now names the worktree
diff and the literal Steps as recovery inputs.

Alternatives: a real Route-table row was the first choice and was rejected on
measurement, not taste. `flow/SKILL.md`'s body was at exactly 300/300 against
`BUDGET_ROUTER_BODY`; a row costs 18 words, and only about 4 could be freed
without deleting a rule. The two ways to buy the row - raising the cap in
`check.sh`, or merging the two REVIEWING rows - were put to the user, who
chose routing the condition from the pointer and keeping the protocol in
`resume.md`. Recorded in `tasks/20260731-174352/DECISION.md`.

Difficulties: `check.sh`'s `direct-state-edit` rule rejected the first draft
of the handoff, which said to "leave the task at its current FLOW STEP" - the
gate reads that as ordering a lifecycle marker written by hand. The rewrite
says what is actually meant: a checkpoint is not a lifecycle transition, so it
runs no `tatr flow`. The gate was right and the prose was sloppy.

The doc sweep then found the real problem. `work/delegation.md`, shipped by
20260731-174348, already described the whole checkpoint handoff, so this diff
would have shipped the same protocol twice in two vocabularies - the exact
defect 20260731-174343's `sweep-for-restatement-not-just-contradiction` lesson
was written about, three commits earlier. The first fix left a stub in
`delegation.md` that pointed on to `flow/resume.md`; round 1 showed that was a
two-hop load for one protocol, so the section is gone entirely and
`work/SKILL.md`'s always-loaded Rules line names `flow/resume.md` directly.
Sweeping for restatement, not just contradiction, found the duplication; only
the reviewer found that the fix itself was half a fix.

Evidence: both `cmd:` proofs were red at base and are green now. All five
conjuncts were sabotaged individually - `/clear`, `/flow <id>`,
`tatr show <id>`, `worktree diff`, `literal Steps` - and each turned its own
proof red while leaving the other green. 20260731-174348's two proofs were
re-run after the `delegation.md` edit and both still pass. `check.sh` clean
(9 skills, 22 rules); `sprout-test.sh` 14/14; `tatr check` and
`tatr check --ledger LESSONS.md` exit 0; `nix flake check` all checks passed.
Budgets after the round-1 fixes: `flow/SKILL.md` body 300/300 (unchanged from
master - the pointer's 3 words are paid for by three one-word cuts, a net-zero
trade, not a saving), `flow/resume.md` 597/600, `work/SKILL.md` body 361/400,
`work/delegation.md` 338/600.

Reflection: two surfaces are now effectively frozen, not one. The flow router
body sits at exactly its cap with zero headroom, and `flow/resume.md` finished
at 597/600 after the round-1 fixes.
The next rule that genuinely belongs in the route table cannot be added by
editing; it will force either a budget decision or a restructure, and this
task only avoided that by having somewhere else to put the protocol.
