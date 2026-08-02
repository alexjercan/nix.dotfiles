---
name: flow
description: Drive one goal through the whole cycle: understand, plan, gate, work, review, compound, land. Use for `/flow` or a full-cycle delivery request.
---

# Flow - Goal to Landed Commit

One task; dispatch phases. Approval owns every context cut.

Resolve ID, else `tatr new`. For an existing ID, `resume.md` selects
`<task-root>`; a new ID has none, so use the main checkout. Read
`tatr -r <task-root> context <id> --phase <phase>`; task prose is not authority.

## Route

`tatr` owns legality. Transitions run `tatr -r <task-root> flow <id>`.

| State | Skill | Result |
|-|-|-|
| BACKLOG | | UNDERSTANDING |
| UNDERSTANDING | | concrete: PLANNING |
| WHAT unknown | `spike` | seeds tasks, `SPIKED <id>` |
| PLANNING | `plan` | PLAN_READY gate |
| PLANNED | `work` | sprout, `--to WORKING` |
| WORKING | `work` | WORK_DONE gate, or fix/review |
| REVIEWING | `review` | verdict |
| REVIEWING + REQUEST_CHANGES | `work` | `--to WORKING`; fix |
| REVIEWING + APPROVE | `review` | `--to COMPOUNDING`; compound |
| COMPOUNDING | `compound` | DONE; LAND_READY gate |
| DONE + branch | | LAND_READY gate; land |

`spike` is a handoff. Unknown WHAT: ask one constraint; record it in
DECISION.md. New work gets its own task.

## Gates

When a phase returns a gate status, load `gates.md` and follow it. Do not
transition, land, or replace its blocking question with passive instructions.

## Stop

Ask on changed meaning, restructuring, inseparable tasks, three disputed
rounds, two blocked fix cycles, or destructive/external action.

## Output

Concise bullets. Include `<id>` and one status: `SPIKED`, `PLAN_READY`,
`WORK_DONE`, `LAND_READY`, or `GOAL DONE`.

## Load on demand

- explicit epic, sprint, version, release, or multi-feature goal -> `epic.md`
- a phase or resume returns PLAN_READY, WORK_DONE, or LAND_READY -> `gates.md`
- LAND_READY was approved, or a land failed -> `landing.md`
- an existing ID, a context checkpoint, or context loss -> `resume.md`
