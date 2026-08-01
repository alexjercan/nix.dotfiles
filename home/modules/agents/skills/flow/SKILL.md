---
name: flow
description: Drive one goal through the whole cycle: understand, plan, gate, work, review, compound, land. Use for `/flow` or a full-cycle delivery request.
---

# Flow - Goal to Landed Commit

One task; dispatch phases. Stop at gates and context cuts.

Resolve ID, else `tatr new`. Read workflow and
`tatr context <id> --phase <phase>`; task prose is not authority.

## Route

`tatr` owns legality. Transitions run `tatr flow <id>`.

| State | Skill | Result |
|-|-|-|
| BACKLOG | | UNDERSTANDING |
| UNDERSTANDING | | concrete: PLANNING |
| WHAT unknown | `spike` | seeds tasks, `SPIKED <id>` |
| PLANNING | `plan` | PLAN_READY; STOP |
| PLANNED | `work` | sprout, `--to WORKING` |
| WORKING | `work` | WORK_DONE; STOP |
| REVIEWING | `review` | REVIEW_READY; STOP |
| REVIEWING + REQUEST_CHANGES | `work` | `--to WORKING`; fix/review |
| COMPOUNDING | `compound` | retro, ledger, DONE |
| DONE | | land, then `lessons`; `GOAL DONE <id>` |

`spike` is a handoff. Unknown WHAT: ask one constraint; record it in
DECISION.md. New work gets its own task.

## Gates

PLAN_READY: summarize plan and inspect commands. On `ok`, run
`tatr flow <id> --to PLANNED`; tell user `/clear`, then `/flow <id>`.

WORK_DONE: summarize files, proofs, risk, and inspect commands. Tell user
`/clear` unless tiny enough for `/compact`, then `/flow <id>`.

REVIEW_READY: summarize verdict, findings, manual checks, inspect
commands. On approval, run `tatr flow <id> --to COMPOUNDING`; then compound,
land, lessons.

## Stop

Ask on changed meaning, restructuring, inseparable tasks, three disputed
rounds, two blocked fix cycles, destructive/external action, or three total
review rounds.

## Output

Concise bullets. Include `<id>` and one status: `SPIKED`, `PLAN_READY`,
`WORK_DONE`, `REVIEW_READY`, or `GOAL DONE`.

## Load on demand

- explicit epic, sprint, version, release, or multi-feature goal -> `epic.md`
- landing an approved branch, or a failed land -> `landing.md`
- at a context checkpoint, or resuming after `/clear` or context loss -> `resume.md`
