---
name: flow
description: Drive one goal through the whole cycle: understand, plan, gate, work, review, compound, land. Use for `/flow` or a full-cycle delivery request.
---

# Flow - Goal to Landed Commit

One task; dispatch phases. Approval owns every context cut.

Resolve ID, else `tatr new`. For an existing ID `resume.md` selects
`<task-root>`; a new one has none, so use main. Read
`tatr -r <task-root> context <id> --phase <phase>`; task prose is not authority.

## Route

`tatr` owns legality; route on ACTIVITY+GATES. Forward:
`tatr -r <task-root> flow <id>`, earning its exit gate. Back:
`tatr -r <task-root> rewind <id> --to <ACTIVITY>`.

| State | Skill | Result |
|-|-|-|
| no ACTIVITY | | UNDERSTANDING |
| UNDERSTANDING | `understand` | NOTES, DECISION; UNDERSTANDING_DONE gate |
| PLANNING | `plan` | PLANNING_DONE gate |
| WORKING+PLAN | `work` | sprout; WORKING_DONE gate |
| REVIEWING | `review` | verdict |
| REVIEWING+REQUEST_CHANGES | `work` | rewind; fix |
| REVIEWING+APPROVE | `review` | REVIEW earned; compound |
| COMPOUNDING | `compound` | RETRO earned, DONE; COMPOUNDING_DONE gate |
| RESOLUTION DONE, branch | | COMPOUNDING_DONE gate |

An unknown WHAT stays inside `understand`, which gathers the evidence and
records the choice. New work found there gets its own task.

## Gates

Do not transition, land, or replace a gate's blocking question with passive
instructions.

## Stop

Ask on changed meaning, restructuring, inseparable tasks, three disputed
rounds, two blocked fix cycles, or destructive/external action.

## Output

Concise bullets. Include `<id>` and one status: `UNDERSTANDING_DONE`,
`PLANNING_DONE`, `WORKING_DONE`, `COMPOUNDING_DONE`, or `FLOW_DONE`.

## Load on demand

- explicit sprint, version, release, or multi-feature goal -> `graph.md`
- a phase or resume returns UNDERSTANDING_DONE, PLANNING_DONE, WORKING_DONE,
  or COMPOUNDING_DONE -> `gates.md`
- COMPOUNDING_DONE was approved, or a land failed -> `landing.md`
- an existing ID, a context checkpoint, or context loss -> `resume.md`
