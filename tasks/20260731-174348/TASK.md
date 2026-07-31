# Bound worker context with delegated checkpoints

- STATUS: OPEN
- PRIORITY: 85
- TAGS: skills,work,parallel,docs,flow
- KIND: STORY
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT
- PARENT: 20260731-174333

## Story

As a worker, I want bounded sequential delegation and durable context
checkpoints, so implementation can stay below roughly 150K active-session
tokens without parallel edits colliding or a resume depending on chat history.

## Steps

- [ ] Add a conditional `home/modules/agents/skills/work/delegation.md` reference
      and route to it from `work/SKILL.md` when context pressure or an
      independently bounded implementation Step justifies a subagent.
- [ ] Define the delegation packet: task ID, branch/worktree, one Step or proof,
      exclusive files/ownership, relevant paths, required checks, and a bounded
      return. Exclude the implementing conversation and unrelated task context.
- [ ] Keep one writer in a worktree. The parent stops editing delegated files,
      waits for the subagent, re-reads its commit/diff, and independently runs
      the proof before integrating or continuing. Parent owns task records,
      lifecycle, and final verification.
- [ ] Route truly parallel, independently landable work to separate Stories and
      sprout worktrees. Do not add parallel edits to one worktree or a generic
      multi-branch integration framework.
- [ ] Define 120K visible tokens as a soft checkpoint and 150K as a hard
      handoff ceiling. When usage is unavailable, trigger on the first
      compaction warning or when the active working set no longer fits a focused
      pass.
- [ ] At a checkpoint, finish an atomic green step when possible, commit it,
      update TASK.md with completed Step, commit/check results and next Step,
      then invoke the flow handoff. Never claim the worker can call `/clear` or
      `/compact` itself.
- [ ] Reconcile the new protocol with `sprout/SKILL.md`, `flow/resume.md`, and
      applicable AGENTS.md surfaces in the documentation sweep.
- [ ] Run all canonical checks.

## Definition of Done

- Work explicitly authorizes bounded subagent delegation with one-writer,
  exclusive-ownership, independent-verification, and bounded-return rules
  (cmd: `rg -q 'exclusive' home/modules/agents/skills/work && rg -q 'one writer' home/modules/agents/skills/work && rg -q 'independent' home/modules/agents/skills/work`).
- Work names the 120K soft checkpoint, 150K hard ceiling, and a fallback when
  token usage is hidden (cmd: `rg -q '120K' home/modules/agents/skills/work && rg -q '150K' home/modules/agents/skills/work && rg -q 'usage.*unavailable|usage.*hidden' home/modules/agents/skills/work`).
- The protocol lowers parent context without trusting delegated work (manual:
  run one bounded delegation, then confirm the parent receives only the stated
  packet result, re-reads the commit, and reruns its proof before proceeding).
- The skill suite remains conformant and within all measured budgets (cmd:
  `rg -q '150K' home/modules/agents/skills/work && bash home/modules/agents/skills/check.sh`).
- Repository checks pass (cmd: `rg -q '150K' home/modules/agents/skills/work && bash home/modules/scripts/sprout-test.sh && tatr check && tatr check --ledger LESSONS.md && nix flake check`).

## Notes

- Sequential delegation in the same worktree is the default because it reduces
  parent context without merge coordination. Parent and subagent never edit it
  concurrently.
- Keep return prose small: commit, changed files, proof results, unresolved
  facts. Durable detail belongs in code/tests/task records.
- The runtime may compact automatically, but automatic compaction is not the
  workflow contract; a durable fresh-session checkpoint is.
