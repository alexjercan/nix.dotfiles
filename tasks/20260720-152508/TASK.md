# Wire tatr check into the tatr, compound, flow and lessons skills

- STATUS: OPEN
- PRIORITY: 75
- TAGS: feature,skills

## Story

As the skills that drive the cycle, I want `tatr check` wired into the loop
so the conformance pass actually runs: documented in the tatr skill, run at
flow Finish and in compound's completion check.

## Steps

- [ ] tatr SKILL.md commands section: document `tatr check` (rules, per-ID
      scoping, --strict, --ledger) matching the shipped tool.
- [ ] compound SKILL.md step 1: `tatr check <id>` is the mechanical half of
      "check the cycle is done".
- [ ] flow SKILL.md Finish: run `tatr check --ledger <ledger path>` before
      /lessons; findings become fixes or new tasks.
- [ ] lessons SKILL.md step 4: the promotion-stalled lint replaces the prose
      "flag at three occurrences" reminder (tool absorbed it - shrink the
      prose).

## Definition of Done

- The four skills reference tatr check at the named points (cmd: grep -rn
  "tatr check" home/modules/agents/skills/{tatr,compound,flow,lessons}/SKILL.md)
- Documented flags match the built tool (cmd: /home/alex/personal/tatr/tatr
  check --help, compared against the skill text)

## Notes

- Depends on: 20260720-152503 (in ~/personal/tatr). Verify flags against the
  locally built binary; the flake input lags until the user pushes tatr and
  bumps flake.lock.
