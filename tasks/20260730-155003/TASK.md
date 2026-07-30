# Adopt tatr v2 and revalidate nix task history

- STATUS: OPEN
- PRIORITY: 50
- TAGS: feature, flow, tatr, migration, testing
- KIND: STORY
- FLOW STEP: PLANNING
- PLAN STATUS: DRAFT
- PARENT: 20260730-153122

## Story

As the nix.dotfiles maintainer, I want to adopt the completed tatr v2 release
and revalidate every local task and skill against it, so the deployed tool and
workflow finish the Epic in one coherent state.

## Steps

- [ ] After the tatr Stories land and their default branch is published,
      update the nix flake's tatr input to the released revision and inspect the
      real CLI/skill output.
- [ ] Run the tatr migration/classification over every nix.dotfiles task,
      preserving historical truth while making each record valid under the v2
      schema and stricter artifact/lesson checks.
- [ ] Resolve every new finding in TASK/SPIKE/DECISION/REVIEW/RETRO and
      LESSONS records; use explicit historical classification where a modern
      phase fact was never recorded rather than inventing it.
- [ ] Exercise the complete Epic -> Story -> plan -> work -> parallel review
      -> compound -> lesson decision -> close -> land path in a scratch fixture
      using the deployed skills and tatr binary.
- [ ] Run the skill conformance check, sprout suite, tatr checks, and flake
      evaluation from the default branch.
- [ ] Update the Epic child index, decision index, manual acceptance list, and
      final verification record.

## Definition of Done

- The lock file references the released tatr revision containing every
  prerequisite Story (cmd: `nix flake metadata --json`).
- Every nix.dotfiles task and ledger passes v2 conformance
  (cmd: `tatr check --ledger LESSONS.md`).
- The end-to-end scratch fixture demonstrates Epic frontier, lazy phase
  context, retained prototype, parallel high-risk review, user lesson
  disposition, and guarded close (test: `flow_v3_end_to_end`).
- Skill and sprout integration suites pass
  (cmd: `bash home/modules/agents/skills/check.sh && bash home/modules/scripts/sprout-test.sh`).
- Flake evaluation passes (cmd: `nix flake check --no-build`).
- Representative final reports meet the agreed output budgets (manual: user
  approves them).

## Notes

- Parent Epic: 20260730-153122.
- Depends on every prior tatr and nix.dotfiles Story in this Epic.
- External prerequisite: the user publishes the landed tatr default branch so
  the GitHub flake input can resolve the new revision.
