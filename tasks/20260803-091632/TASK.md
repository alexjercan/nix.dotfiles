# Gate understanding on a NOTES.md scratchpad the user approves

- PRIORITY: 90
- TAGS: skills, flow, afk, docs
- KIND: TASK
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE

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

- [x] Write `home/modules/agents/skills/flow/understanding.md` (at most 600
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
- [x] Edit `home/modules/agents/skills/flow/SKILL.md`: the UNDERSTANDING route
      row produces the `NOTES_READY` gate; add `NOTES_READY` to the `## Output`
      status list and to the `gates.md` pointer condition; add the pointer
      `- ACTIVITY is UNDERSTANDING, or the task is new -> `understanding.md``.
      The body is at 299 of its 300-word budget, so trim prose in the same edit
      rather than raising the budget.
- [x] Edit `home/modules/agents/skills/flow/gates.md`: add the row
      `| `NOTES_READY` | `Approve understanding - move to PLANNING` | Run
      `tatr -r <task-root> flow <id>`. |`, extend the opening sentence and the
      "Continue or stop" paragraph to cover it, and keep the file at most 600
      words.
- [x] Edit `home/modules/agents/skills/flow/resume.md`: add an UNDERSTANDING
      bullet to `## Reconstruct a pending gate` - resume to `NOTES_READY` only
      with a NOTES.md carrying every required section and no unanswered
      blocking question. Currently 489 of 600 words.
- [x] Edit `home/modules/agents/skills/plan/SKILL.md` step 1 to read
      `tasks/<id>/NOTES.md` when present, as input and not authority. The body
      is at 398 of 400 words, so trim in the same edit.
- [x] Edit `home/modules/scripts/afk.sh`: add `NOTES_READY  the understanding
      gate is pending` to the PROTOCOL status list, and a `run_item` case
      branch `lifecycle_gate NOTES_READY UNDERSTANDING "Approve understanding -
      move to PLANNING" activity PLANNING "understanding ready"`, shaped like
      the `WORK_DONE` branch (activity postcondition, `prev_fp=""` on success,
      `rotate_stopped` otherwise). The approve label must match `gates.md`
      byte for byte.
- [x] Edit `home/modules/scripts/afk-test.sh`: rewire `gen_goal_cycle` so
      invocation 1 stops at UNDERSTANDING and reports `AFK NOTES_READY`, its
      gate resume runs `tatr flow` into PLANNING, and the plan session follows
      - keeping `gen_work_to_land`'s base offsets consistent. Add failure-path
      checks in `test_failure_paths`: `NOTES_READY` reported from PLANNING
      fails without answering the gate, and an approval that leaves the cursor
      in UNDERSTANDING fails the run.
- [x] Grep the new route: `grep -rn NOTES_READY` over `home/` and `AGENTS.md`,
      listing every gate and status list now active, and confirm each one is
      the intended edit.
- [x] Update the repo `AGENTS.md` afk-vocabulary sentence to route on
      `NOTES_READY` alongside `SPIKED`, `PLAN_READY`, `WORK_DONE` and
      `LAND_READY`.
- [x] Run the check suite: `bash home/modules/agents/skills/check.sh`,
      `bash home/modules/scripts/afk-test.sh`, `nix flake check`, `tatr check`.

## Definition of Done

- [x] `flow/understanding.md` fixes the six NOTES.md sections and is reachable
      from a `flow/SKILL.md` pointer (cmd: `bash -c 'test "$(grep -c "^## " home/modules/agents/skills/flow/understanding.md)" -ge 6 && grep -q "understanding.md" home/modules/agents/skills/flow/SKILL.md'`)
- [x] The `NOTES_READY` gate is declared in every file that carries the flow
      status vocabulary (cmd: `grep -l NOTES_READY home/modules/agents/skills/flow/SKILL.md home/modules/agents/skills/flow/gates.md home/modules/agents/skills/flow/understanding.md home/modules/agents/skills/flow/resume.md home/modules/scripts/afk.sh home/modules/scripts/afk-test.sh AGENTS.md`)
- [x] The approve label is byte-identical in `gates.md` and `afk.sh`
      (cmd: `bash -c 'grep -q "Approve understanding - move to PLANNING" home/modules/agents/skills/flow/gates.md && grep -q "Approve understanding - move to PLANNING" home/modules/scripts/afk.sh'`)
- [x] Every skill budget and reference rule still holds after the trims
      (cmd: `bash home/modules/agents/skills/check.sh`)
- [x] afk drives the understanding gate and rejects it from the wrong activity
      (test: `bash -c 'grep -q NOTES_READY home/modules/scripts/afk-test.sh && bash home/modules/scripts/afk-test.sh'`)
- [x] Flake evaluation and the deployment tree still hold
      (cmd: `nix flake check`)
- [x] Task records stay schema-clean (cmd: `tatr check`)
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

## Close-out

WHAT: understanding is now a real phase with a body and a stop.
`flow/understanding.md` (310 words) states the phase and fixes NOTES.md's six
sections; `flow/SKILL.md`, `flow/gates.md`, `flow/resume.md`, `plan/SKILL.md`,
`afk.sh`, `afk-test.sh` and `AGENTS.md` carry the `NOTES_READY` vocabulary.
`tatr` is unchanged.

WHY: `TASK.md` is a plan, not a briefing. The gate is what forces the briefing
to exist before planning consumes the context that produced it.

ALTERNATIVES: recorded in DECISION.md and unchanged by the implementation.

DIFFICULTIES:

- The `gates.md` pointer in `flow/SKILL.md` had to keep condition text on the
  arrow's own line. Wrapping the four statuses so the arrow started a line
  would have tripped `empty-pointer-condition`, which reads only that line.
- Both tight budgets needed real trims, not reflows. `flow/SKILL.md` gave up
  "load `gates.md` and follow it" (the `## Load on demand` pointer already
  states the condition); `plan/SKILL.md` gave up "flow owns the approval
  gate", which its next clause implies. Round 1 spent the last of the
  headroom, so both bodies now sit exactly at 300/300 and 400/400.
- The DoD's six-section proof counts `^## ` in `understanding.md` itself, so
  the NOTES.md template is a fenced block with the headings at column 0 -
  grep sees them, a reader sees a template.
- `gen_goal_cycle` grew from 6 invocations to 8, which moved every index the
  goal-cycle tests assert on (worker 1 3 5 7, gate resumes 2 4 6 8, four
  auto-approved gates) and the `gen_work_to_land` base offset from 2 to 4.
- `seed_working_task` was split: `seed_task` mints the ID, `seed_task_at`
  parks a task at UNDERSTANDING or PLANNING for the two new failure paths.
- Round 1 (R1.2) found the gate had no teeth under afk: the other two gates
  are enforced by `tatr` refusing the transition, but UNDERSTANDING ->
  PLANNING is unconditional, so a session could earn the stop by running
  `tatr flow` twice. `afk.sh` now checks the artifact itself via
  `require_record`. The activity is checked twice in that branch - once
  explicitly, once inside `lifecycle_gate` - so that a task already past
  UNDERSTANDING still reports the state disagreement rather than a missing
  scratchpad it was never asked for.
- Round 1 (R1.1) found the doc-surface sweep had missed
  `review/dimensions.md`, which named NOTES.md as a documentation surface -
  directly contradicted by `understanding.md`'s "not maintained once work
  starts". The `NOTES_READY` grep could not have caught it: the stale mention
  says "NOTES.md", not the new status. Absorbing the correction pushed
  `dimensions.md` to exactly 600/600 and `flow/SKILL.md` to 300/300.
- Round 2 (R2.1) caught this record contradicting itself: the round-1 fixes
  moved two budget numbers and restored a clause the DIFFICULTIES bullet still
  claimed was cut. A close-out written before the last commit is a claim about
  a tree that no longer exists.
- Round 2 (R2.2) killed a check that passed for the wrong reason: with
  `require_record` deleted the missing-NOTES.md run still exits non-zero, so
  only the failure reason and the invocation count falsify anything.

EVIDENCE: `check.sh` clean (8 skills, 23 rules); `afk-test.sh` 19/19;
`nix flake check` all 6 checks; `tatr check` clean; all seven `cmd`/`test`
proofs re-run green after the round-1 fixes. The two original failure-path
cases were falsified by deleting the `NOTES_READY` branch from `afk.sh` and
re-running: `is in PLANNING`, `PLANNING or later`, `is in UNDERSTANDING` and
the answered-once count all failed, then passed again once restored. The
round-1 cases were falsified the same way: deleting the `require_record` call
fails `the missing scratchpad is named` and `the unbriefed gate was never
answered`, and typoing `seed_task_at`'s argument now fails the run instead of
silently seeding PLANNING.

REFLECTION: the shared-vocabulary rule in `AGENTS.md` paid for itself - the
grep step found every site, and nothing had to be discovered by a failing
test. What it does not cover is the TEST fixtures' arithmetic: adding one
session to the goal cycle rewrites index constants in four tests, and only
running them finds that. A fixture that named its sessions rather than
numbering them would not have that cost. The second gap the rule leaves is
the one R1.1 fell into: it routes on the new token, so prose that describes
the changed concept in its own words stays invisible to the grep. Sweeping
the noun (`NOTES.md`) as well as the status would have found it.
