---
name: flow
description: Drive one goal through the whole cycle: understand, plan, gate, work, review, compound, land. Use for `/flow` or a full-cycle delivery request.
---

# Flow - Goal to Landed Commit

A state machine over ONE tatr task. It dispatches phases; it never restates
their rules.

## 1. Resolve the task

`flow task <id>`, or an ID in the request, names the task. Otherwise
`tatr new` ONE task for the requested thing - a container only if the user
asks for a sprint, release, epic or multi-feature goal.

Load context with `tatr context <id> --phase <phase>`, not the whole task
folder. Read the repository's `## Agent workflow` AGENTS.md cache first.

## 2. Understand

Compare the request, TASK.md and the code; task text is context, not
authority. `tatr flow <id>` to UNDERSTANDING, then PLANNING once the concrete
artifact is pinned down.

Ask the user when the request underspecifies WHAT to build - the artifact or
mechanism, not just its placement or look - naming the constraint that makes
the candidates mutually exclusive. Record the answer in a DECISION.md.

## 3. Plan, then GATE

Invoke `plan`, present its package, and STOP: no worktree, branch or code
until the user says build it. `tatr flow <id> --to PLANNED` then writes
`PLAN STATUS: APPROVED`, the only proof work may start.

## 4. Work and review until APPROVE

Per work task, highest priority first:

1. Read the lessons ledger and apply it.
2. Invoke `work`. It sprouts the worktree and moves the task to WORKING.
3. Invoke `review`. Alternate it with `work` until the verdict is APPROVE;
   `tatr flow <id> --to WORKING` is the fix loop.
4. On APPROVE invoke `compound` BEFORE landing, so the retro lands in the same
   commit.
5. Land the branch, then report one line ending with `DONE <id>`.

New work found mid-flow becomes a tatr task in the current worktree, not a
wider diff. A mid-flow lesson re-audits the queued tasks it invalidates.

## 5. Finish

Run the repository's canonical checks on the default branch, verify every
`tatr proofs <id>` proof, run `tatr check --ledger <ledger>`, then invoke
`lessons`.

## Stop and ask when

- the plan needs restructuring, not one more task;
- the goal means something other than assumed;
- seeded tasks turn out inseparable without throwaway shims;
- a review dispute survives three rounds;
- the same task fails work-review twice with no path forward;
- anything destructive or outward-facing comes up (push, deploy, data).

## Output

40 words or fewer, plus the terminal status line - the LAST line of the phase
report: `SPIKED <id>`, `PLANNED <id>`, `DONE <id>`, `GOAL DONE <id>`, one id
each; `DONE` fires only after the branch lands. Detail lives in the records;
chat points at them.

## Load on demand

Read one ONLY when its condition holds.

- the user asked for an epic, sprint, release or multi-feature goal -> `epic.md`
- landing an approved branch, or a land that failed -> `landing.md`
- resuming a run this session did not start, or lost its context -> `resume.md`
