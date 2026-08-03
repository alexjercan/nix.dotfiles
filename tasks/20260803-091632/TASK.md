# Gate understanding on a NOTES.md scratchpad the user approves

- PRIORITY: 90
- TAGS: skills, flow, afk, docs
- KIND: TASK
- ACTIVITY: WORKING
- GATES: PLAN
- RESOLUTION: -

Understanding is the one flow phase with no skill text and no stop. The router
walks `no ACTIVITY -> UNDERSTANDING -> PLANNING` in one motion, so the first
artifact a user ever sees is `TASK.md`: correct Steps and proofs, but it never
says what the change will DO, which files it lands in, or which data structures
and functions appear. `tatr/records.md` already blesses an optional `NOTES.md`
and two past tasks used one ad hoc; nothing tells a phase to write one.

Give understanding a body and a stop. It writes `tasks/<id>/NOTES.md` - a
fixed-shape scratchpad aimed at a human reading cold - and returns a new
`NOTES_READY` gate that blocks before planning starts. `tatr` needs no change:
leaving UNDERSTANDING earns no gate, so this is a skills-level approval gate
like the three that exist. `afk.sh` does need one, because it routes on the
skills' status vocabulary and would die on an unknown status.

## Steps

- [ ] Write `home/modules/agents/skills/flow/understanding.md` (at most 600
      words, one level deep). It states the phase: read
      `tatr -r <task-root> context <id> --phase understand` plus the code the
      goal names; restate the goal in one line; ask blocking clarifying
      questions only where two readings produce materially different work;
      write `tasks/<id>/NOTES.md`; present it and return `NOTES_READY <id>`.
      It fixes NOTES.md's sections: `## What changes` (user-visible behavior,
      before and after), `## Surfaces` (each file, module or crate touched, one
      line of why), `## Data and interfaces` (data structures, functions,
      methods and types added or changed, with signatures), `## Sketches` (a
      few indicative diff lines per key change, marked illustrative, never a
      full patch), `## Shape` (an ASCII flow or component diagram; mermaid only
      when ASCII cannot carry it), `## Consequences and open questions`. It
      states that NOTES.md is a scratchpad, not a spec: `TASK.md` stays the
      plan's authority, and NOTES.md is not a proof and is not maintained once
      work starts.
- [ ] Edit `home/modules/agents/skills/flow/SKILL.md`: the UNDERSTANDING route
      row produces the `NOTES_READY` gate; add `NOTES_READY` to the `## Output`
      status list and to the `gates.md` pointer condition; add the pointer
      `- ACTIVITY is UNDERSTANDING, or the task is new -> `understanding.md``.
      The body is at 299 of its 300-word budget, so trim prose in the same edit
      rather than raising the budget.
- [ ] Edit `home/modules/agents/skills/flow/gates.md`: add the row
      `| `NOTES_READY` | `Approve understanding - move to PLANNING` | Run
      `tatr -r <task-root> flow <id>`. |`, extend the opening sentence and the
      "Continue or stop" paragraph to cover it, and keep the file at most 600
      words.
- [ ] Edit `home/modules/agents/skills/flow/resume.md`: add an UNDERSTANDING
      bullet to `## Reconstruct a pending gate` - resume to `NOTES_READY` only
      with a NOTES.md carrying every required section and no unanswered
      blocking question. Currently 489 of 600 words.
- [ ] Edit `home/modules/agents/skills/plan/SKILL.md` step 1 to read
      `tasks/<id>/NOTES.md` when present, as input and not authority. The body
      is at 398 of 400 words, so trim in the same edit.
- [ ] Edit `home/modules/scripts/afk.sh`: add `NOTES_READY  the understanding
      gate is pending` to the PROTOCOL status list, and a `run_item` case
      branch `lifecycle_gate NOTES_READY UNDERSTANDING "Approve understanding -
      move to PLANNING" activity PLANNING "understanding ready"`, shaped like
      the `WORK_DONE` branch (activity postcondition, `prev_fp=""` on success,
      `rotate_stopped` otherwise). The approve label must match `gates.md`
      byte for byte.
- [ ] Edit `home/modules/scripts/afk-test.sh`: rewire `gen_goal_cycle` so
      invocation 1 stops at UNDERSTANDING and reports `AFK NOTES_READY`, its
      gate resume runs `tatr flow` into PLANNING, and the plan session follows
      - keeping `gen_work_to_land`'s base offsets consistent. Add failure-path
      checks in `test_failure_paths`: `NOTES_READY` reported from PLANNING
      fails without answering the gate, and an approval that leaves the cursor
      in UNDERSTANDING fails the run.
- [ ] Grep the new route: `grep -rn NOTES_READY` over `home/` and `AGENTS.md`,
      listing every gate and status list now active, and confirm each one is
      the intended edit.
- [ ] Update the repo `AGENTS.md` afk-vocabulary sentence to route on
      `NOTES_READY` alongside `SPIKED`, `PLAN_READY`, `WORK_DONE` and
      `LAND_READY`.
- [ ] Run the check suite: `bash home/modules/agents/skills/check.sh`,
      `bash home/modules/scripts/afk-test.sh`, `nix flake check`, `tatr check`.

## Definition of Done

- [ ] `flow/understanding.md` fixes the six NOTES.md sections and is reachable
      from a `flow/SKILL.md` pointer (cmd: `bash -c 'test "$(grep -c "^## " home/modules/agents/skills/flow/understanding.md)" -ge 6 && grep -q "understanding.md" home/modules/agents/skills/flow/SKILL.md'`)
- [ ] The `NOTES_READY` gate is declared in every file that carries the flow
      status vocabulary (cmd: `grep -l NOTES_READY home/modules/agents/skills/flow/SKILL.md home/modules/agents/skills/flow/gates.md home/modules/agents/skills/flow/understanding.md home/modules/agents/skills/flow/resume.md home/modules/scripts/afk.sh home/modules/scripts/afk-test.sh AGENTS.md`)
- [ ] The approve label is byte-identical in `gates.md` and `afk.sh`
      (cmd: `bash -c 'grep -q "Approve understanding - move to PLANNING" home/modules/agents/skills/flow/gates.md && grep -q "Approve understanding - move to PLANNING" home/modules/scripts/afk.sh'`)
- [ ] Every skill budget and reference rule still holds after the trims
      (cmd: `bash home/modules/agents/skills/check.sh`)
- [ ] afk drives the understanding gate and rejects it from the wrong activity
      (test: `bash -c 'grep -q NOTES_READY home/modules/scripts/afk-test.sh && bash home/modules/scripts/afk-test.sh'`)
- [ ] Flake evaluation and the deployment tree still hold
      (cmd: `nix flake check`)
- [ ] Task records stay schema-clean (cmd: `tatr check`)
- [ ] A real `/flow` on a fresh goal stops at `NOTES_READY` with a NOTES.md a
      cold reader can act on (manual: user judgement)

## Notes

- Decided with the user: a full `NOTES_READY` gate (not an inline
  confirmation), and a fixed section list (not a loose menu). See DECISION.md.
- `tatr` is unchanged. Confirmed in scratch: `tatr new` leaves `ACTIVITY: -`,
  `tatr flow` moves `- -> UNDERSTANDING` with no gate, and
  `tatr context <id> --phase understand` lists TASK/SPIKE/DECISION only - so
  NOTES.md is named by the skills, not surfaced by tatr.
- `check.sh` stays untouched: every new file and edit is checked by the
  existing structural rules. `flow/understanding.md` lives in an already
  deployed skill directory, so `skills-deployment-tree` needs no new entry.
- Two budgets have almost no headroom (`flow/SKILL.md` 299/300,
  `plan/SKILL.md` 398/400). Trimming prose is part of those Steps; raising a
  budget is a design change and is out of scope.
- `afk.sh` already prints "working out what to build" for UNDERSTANDING
  (`phase_label`), so the reporting half needs no change.
- The gate cuts context like the others: transition, commit the task records,
  then `/clear` and `/flow <id>`. Planning re-reads NOTES.md from disk.
