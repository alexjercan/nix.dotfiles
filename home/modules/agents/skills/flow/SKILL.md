---
name: flow
description: Drive one goal through the whole cycle: understand, plan, gate, work, review, compound, land. Use for `/flow` or a full-cycle delivery request.
---

# Flow - Goal to Landed Commit

State machine over ONE tatr task. Dispatch phases; do not restate them.

## Route

1. Resolve an ID from the request, else `tatr new` one task. Use a container
   only for an explicit sprint, release, epic, or multi-feature goal.
2. Read the repository's `## Agent workflow`, then
   `tatr context <id> --phase <phase>`. Compare request, code, and TASK.md;
   task prose is context, not authority.
3. Use `tatr flow <id>` to UNDERSTANDING, then PLANNING after the artifact is
   concrete. If WHAT remains ambiguous, ask with the mutually exclusive
   constraint and record the answer in DECISION.md.
4. Invoke `plan`, present it, and STOP. Only the user's build approval permits
   `tatr flow <id> --to PLANNED` and any worktree or implementation.
5. Read the ledger. Invoke `work`, then `review`; repeat through
   `tatr flow <id> --to WORKING` until APPROVE. Invoke `compound` before
   landing. Land, then report `DONE <id>`.
6. On the default branch, run canonical checks and every `tatr proofs <id>`
   proof. Invoke `lessons`; settle pending promotions with the user. Require
   `tatr check --ledger <ledger>` clean.

New work gets its own task in the current worktree. A new lesson re-audits
affected queued tasks.

## Stop

Ask on changed meaning, plan restructuring, inseparable tasks, three disputed
review rounds, two blocked work-review cycles, or destructive/external action.

## Output

At most 40 words plus a last status line: `SPIKED <id>`, `PLANNED <id>`,
`DONE <id>`, or `GOAL DONE <id>`. `DONE` requires landing.

## Load on demand

- explicit epic, sprint, version, release, or multi-feature goal -> `epic.md`
- landing an approved branch, or a failed land -> `landing.md`
- resuming work this session did not start, or after context loss -> `resume.md`
