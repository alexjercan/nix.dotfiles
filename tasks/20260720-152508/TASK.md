# Wire tatr check into the tatr, compound, flow and lessons skills

- STATUS: CLOSED
- PRIORITY: 75
- TAGS: feature, skills

## Story

As the skills that drive the cycle, I want `tatr check` wired into the loop
so the conformance pass actually runs: documented in the tatr skill, run at
flow Finish and in compound's completion check.

## Steps

- [x] tatr SKILL.md commands section: document `tatr check` (rules, per-ID
      scoping, --strict, --ledger) matching the shipped tool.
- [x] compound SKILL.md step 1: `tatr check <id>` is the mechanical half of
      "check the cycle is done".
- [x] flow SKILL.md Finish: run `tatr check --ledger <ledger path>` before
      /lessons; findings become fixes or new tasks.
- [x] lessons SKILL.md step 4: point the promotion-threshold prose at the
      promotion-stalled lint. (Amended from "replace/shrink the prose": the
      lint detects a stalled promotion but does not say what to do about
      it, so the move-instruction stays and gained the lint pointer plus
      the bare-counts convention - recorded in review R1.2.)

## Definition of Done

- The four skills reference tatr check at the named points (cmd: grep -rn
  "tatr check" home/modules/agents/skills/{tatr,compound,flow,lessons}/SKILL.md)
- Documented flags match the built tool (cmd: /home/alex/personal/tatr/tatr
  check --help, compared against the skill text)

## Notes

- Depends on: 20260720-152503 (in ~/personal/tatr). Verify flags against the
  locally built binary; the flake input lags until the user pushes tatr and
  bumps flake.lock.

## Close-out (2026-07-20)

What changed: tatr SKILL.md documents check (command block line + rules
bullet, flags verified against the freshly rebuilt master binary, not the
skill author's memory); compound step 1 makes `tatr check <id>` the
mechanical half of the cycle-done gate; flow's Finish runs
`tatr check --ledger <path>` as a conformance pass before /lessons; the
lessons skill's promotion-threshold prose now points at the
promotion-stalled lint instead of relying on vigilance (the lint replaces
the reminder; the flag-it-do-not-self-promote rule stays).

Dogfood evidence: `tatr -r <this repo> check --ledger docs/LESSONS.md`
exits 0 on the repo's own backlog including this flow's artifacts.

Known limitation recorded honestly: an annotated count like
"(x3, PROMOTED ...)" does not parse as a counter, so annotated lessons are
invisible to the promotion-stalled lint. For promoted lessons that is the
desired outcome (they should not stall); an unpromoted "(x3, note)" would
evade. Convention: keep counts bare until promotion; the annotation IS the
promotion marker.

Difficulties: none beyond a stale ./tatr binary in the tatr main checkout
(pre-check build artifact) - rebuilt before verifying flags, per the DoD's
match-the-built-tool proof.
