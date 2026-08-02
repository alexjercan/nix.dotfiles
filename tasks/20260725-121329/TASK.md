# Record epic flow in TASK.md only

- PRIORITY: 80
- TAGS: docs, skills, flow
- KIND: TASK
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE

## Story

As the flow user, I want epic/container flow to keep its durable record in
`TASK.md`, so the skills have one task-file source of truth and never mention
or create a separate goal sidecar.

## Steps

- [x] Update `flow/SKILL.md` so explicit epic/container runs record the epic
      statement, done criteria, child task list, decision index, and manual
      acceptance directly in the container `TASK.md`.
- [x] Remove all `GOAL.md` mentions from every live skill file under
      `home/modules/agents/skills/`.
- [x] Remove legacy `GOAL.md` backward-compatibility language from plan/work
      handoff rules; require the approved Flow State marker.
- [x] Update live repo guidance outside tasks if it still describes `GOAL.md`
      as part of the active flow.
- [x] Run the tatr gates and the repo check suite.

## Definition of Done

- No live skill file mentions `GOAL.md`
  (cmd: `rg -n "GOAL\\.md" home/modules/agents/skills` exits 1).
- Flow documents epic/container records in `TASK.md`
  (cmd: `grep -n "Child Tasks" home/modules/agents/skills/flow/SKILL.md`).
- Planning/work handoff no longer names `GOAL.md`
  (cmd: `rg -n "GOAL\\.md" home/modules/agents/skills/{plan,work,tatr}/SKILL.md` exits 1).
- nix.dotfiles tatr gates pass
  (cmd: `/home/alex/personal/tatr/tatr check` and
  `/home/alex/personal/tatr/tatr check --ledger LESSONS.md`).
- nix.dotfiles check suite passes
  (cmd: `bash home/modules/scripts/sprout-test.sh` and
  `nix flake check --no-build`).

## Notes

- Do not migrate historical task folders unless the user explicitly asks.
- This task intentionally drops `GOAL.md` from the live skill vocabulary rather
  than preserving backward-compatibility instructions.

## Work Notes

- Updated `flow/SKILL.md` so the default shape stays one request to one task,
  and explicit epic/sprint/version/release containers store their broader
  statement, done criteria, child task queue, decision index, and manual
  acceptance directly in the container `TASK.md`.
- Updated `plan/SKILL.md`, `work/SKILL.md`, and `tatr/SKILL.md` so the handoff
  rules no longer preserve a legacy sidecar path. `/work` now documents one
  gate for flow-managed tasks: `PLAN STATUS: APPROVED`.
- Swept live repo guidance under `AGENTS.md` and `home/modules/agents`; no
  active guidance outside historical task records still names the removed
  sidecar.

## Verification

- `rg -n "GOAL\\.md" home/modules/agents/skills` exited 1 with no output.
- `rg -n "GOAL\\.md" AGENTS.md home/modules/agents` exited 1 with no output.
- `grep -n "Child Tasks" home/modules/agents/skills/flow/SKILL.md` matched the
  child-task update path and section template.
- `/home/alex/personal/tatr/tatr check` passed.
- `/home/alex/personal/tatr/tatr check --ledger LESSONS.md` passed.
- `bash home/modules/scripts/sprout-test.sh` passed.
- `nix flake check --no-build` passed after rerunning outside the sandbox,
  because the first run could not open `/home/alex/.cache/nix`.

## Reflection

- The useful decision was to make the requested non-backward-compatible break
  explicit in the handoff rules instead of preserving multiple ways to infer
  planning state.
- The only snag was Nix cache access under the sandbox. Rerunning the same
  command with normal cache permissions proved the check itself was green.
- Next time, treat "do not keep backward compatibility" as a prompt to remove
  fallback language from every related skill section before writing close-out
  notes.
