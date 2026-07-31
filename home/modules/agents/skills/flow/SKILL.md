---
name: flow
description: Drive one goal through the whole cycle: understand, plan, gate, work, review, compound, land. Use for `/flow` or a full-cycle delivery request.
---

# Flow - Goal to Landed Commit

One tatr task; dispatch phases, never restate.

Resolve an ID, else `tatr new` one task. Read `## Agent workflow` and
`tatr context <id> --phase <phase>`; task prose is context, not authority.

## Route

`tatr` owns legality; this table owns routing. Transitions run
`tatr flow <id>`; `--to` spells the target. Only the fix loop reverses.

| State / condition | Skill | Transition / result |
|-|-|-|
| BACKLOG | | UNDERSTANDING |
| UNDERSTANDING | | artifact concrete: PLANNING |
| UNDERSTANDING + WHAT unknown | `spike` | stay; seeds tasks, `SPIKED <id>` |
| PLANNING | `plan` | present, STOP; approval: `--to PLANNED` |
| PLANNED | `work` | ledger, sprout, `--to WORKING` |
| WORKING | `work` | commit code, records; REVIEWING |
| REVIEWING | `review` | APPROVE: COMPOUNDING |
| REVIEWING + REQUEST_CHANGES | `work` | `--to WORKING`, then `review` |
| COMPOUNDING | `compound` | commit retro, ledger; DONE |
| DONE | | land; `DONE <id>` |
| Landed, default branch | `lessons` | checks, proofs, `tatr check --ledger`; goals end `GOAL DONE <id>` |

`spike` is a conditional handoff, not a lifecycle state. Ambiguous WHAT: ask a
mutually exclusive constraint, recorded in DECISION.md. New work becomes its
own task here; a new lesson re-audits queued tasks.

## Stop

Ask on changed meaning, plan restructuring, inseparable tasks, three disputed
review rounds, two blocked work-review cycles, or destructive/external action.

## Output

At most 40 words plus a last status line, `<id>` included: `SPIKED`,
`PLANNED`, `DONE`, or `GOAL DONE`. `DONE` requires landing.

## Load on demand

- explicit epic, sprint, version, release, or multi-feature goal -> `epic.md`
- landing an approved branch, or a failed land -> `landing.md`
- resuming work started elsewhere or after context loss -> `resume.md`
