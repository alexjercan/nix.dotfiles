# Bound worker context with delegated checkpoints

- PRIORITY: 85
- TAGS: skills, work, parallel, docs, flow
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE
- PARENT: 20260731-174333

## Story

As a worker, I want bounded sequential delegation and durable context
checkpoints, so implementation can stay below roughly 150K active-session
tokens without parallel edits colliding or a resume depending on chat history.

## Steps

- [x] Add a conditional `home/modules/agents/skills/work/delegation.md` reference
      and route to it from `work/SKILL.md` when context pressure or an
      independently bounded implementation Step justifies a subagent.
- [x] Define the delegation packet: task ID, branch/worktree, one Step or proof,
      exclusive files/ownership, relevant paths, required checks, and a bounded
      return. Exclude the implementing conversation and unrelated task context.
- [x] Keep one writer in a worktree. The parent stops editing delegated files,
      waits for the subagent, re-reads its commit/diff, and independently runs
      the proof before integrating or continuing. Parent owns task records,
      lifecycle, and final verification.
- [x] Route truly parallel, independently landable work to separate Stories and
      sprout worktrees. Do not add parallel edits to one worktree or a generic
      multi-branch integration framework.
- [x] Define 120K visible tokens as a soft checkpoint and 150K as a hard
      handoff ceiling. When usage is unavailable, trigger on the first
      compaction warning or when the active working set no longer fits a focused
      pass.
- [x] At a checkpoint, finish an atomic green step when possible, commit it,
      update TASK.md with completed Step, commit/check results and next Step,
      then invoke the flow handoff. Never claim the worker can call `/clear` or
      `/compact` itself.
- [x] Reconcile the new protocol with `sprout/SKILL.md`, `flow/resume.md`, and
      applicable AGENTS.md surfaces in the documentation sweep.
- [x] Run all canonical checks.

## Definition of Done

- Work explicitly authorizes bounded subagent delegation with one-writer,
  exclusive-ownership, independent-verification, and bounded-return rules
  (cmd: `rg -q 'exclusively owns' home/modules/agents/skills/work/delegation.md && rg -q 'one writer at a time' home/modules/agents/skills/work/delegation.md && rg -q 'runs the proof independently' home/modules/agents/skills/work/delegation.md && rg -q 'What it RETURNS' home/modules/agents/skills/work/delegation.md`).
- Work names the 120K soft checkpoint, 150K hard ceiling, and a fallback when
  token usage is hidden (cmd: `rg -q '120K' home/modules/agents/skills/work/SKILL.md && rg -q '150K' home/modules/agents/skills/work/SKILL.md && rg -q '120K' home/modules/agents/skills/work/delegation.md && rg -q '150K' home/modules/agents/skills/work/delegation.md && rg -q 'usage is unavailable' home/modules/agents/skills/work/SKILL.md && rg -q 'usage is unavailable' home/modules/agents/skills/work/delegation.md`).
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

## Close-out

What/why: implementation context is now bounded by two named mechanisms.
`work/SKILL.md` `## Rules` carries the trigger (checkpoint at 120K visible
tokens, hand off at 150K, fall back to the first compaction warning or a
working set that no longer fits one focused pass), and the new conditional
`work/delegation.md` carries the protocol: the RECEIVES/RETURNS packet, the
one-writer rule, independent re-verification by the parent, parallel work
routed to its own Story and worktree, and the checkpoint-to-fresh-session
sequence.

Alternatives: putting the thresholds only in `delegation.md` was rejected -
the reference loads on "context pressure", so an agent that has not yet
noticed the pressure would never read the number that defines it. The trigger
must sit in the always-loaded body and the protocol in the reference.
A second reference for checkpointing was also rejected: delegation and
checkpointing share one trigger and one condition, so they share one file.

Difficulties: the doc sweep found `review/rounds.md` asserting the round-1
reviewer is "on most diffs the suite's only subagent", which this task
falsifies. Rewriting it to point at `work/delegation.md` pushed the file to
601 words against its 600 cap; the replacement was tightened to 594. This is
the neighboring-contract rule from 20260731-142000 firing on the first task
after it landed. The sweep's other three surfaces were read and found already
consistent: `sprout/SKILL.md` ("one task per feature/worktree"), the skills
README, and `flow/resume.md`, whose receiving side needs no change here.

Evidence: both `cmd:` proofs were red at base - `delegation.md` did not exist.
Every conjunct was sabotaged individually and each turned its proof red: four
in the delegation proof, six in the threshold proof (both tokens in both
files). `check.sh` clean (9 skills, 22 rules); `sprout-test.sh` 14/14;
`tatr check` and `tatr check --ledger LESSONS.md` exit 0; `nix flake check`
all checks passed. Budgets: `work/SKILL.md` body 358/400, `delegation.md`
462/600, `review/rounds.md` 589/600 after the round-1 fixes.

Reflection: the plan's own DoD proof for the delegation rules was already
GREEN on master before any code existed, because `rg -q 'independent'` matched
`verify.md`. Both proofs were rescoped to per-file conjuncts before
implementation, applying the `proof-must-cover-its-conjunct` lesson recorded
by the previous Story in this Epic.
