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

`tatr` owns legality; route on ACTIVITY+GATES. Forward:
`tatr -r <task-root> flow <id>`, earning its exit gate. Back:
`tatr -r <task-root> rewind <id> --to <ACTIVITY>`.

| State | Skill | Result |
|-|-|-|
| no ACTIVITY | | UNDERSTANDING |
| UNDERSTANDING | | concrete: PLANNING |
| WHAT unknown | `spike` | seeds tasks, `SPIKED` |
| PLANNING | `plan` | PLAN_READY gate |
| WORKING+PLAN | `work` | sprout; WORK_DONE gate |
| REVIEWING | `review` | verdict |
| REVIEWING+REQUEST_CHANGES | `work` | rewind; fix |
| REVIEWING+APPROVE | `review` | REVIEW earned; compound |
| COMPOUNDING | `compound` | RETRO earned, DONE; LAND_READY gate |
| RESOLUTION DONE, branch | | LAND_READY gate |

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
