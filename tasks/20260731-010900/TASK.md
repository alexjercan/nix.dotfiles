# Decide whether the live-agent skill behavior pass is worth automating

- STATUS: OPEN
- PRIORITY: 20
- TAGS: skills,flow,testing,decision
- KIND: STORY
- FLOW STEP: BACKLOG
- PLAN STATUS: DRAFT
- PARENT: 20260730-153122
- DEPENDS ON: 20260730-142533

## Story

As the flow-suite maintainer, I want the live-agent behavior that
`skills/check.sh` deliberately cannot observe to be exercised repeatably, so
that "the model actually loaded only the guarded files" stops being a claim
nobody re-checks after the first manual pass.

## Notes

- Seeded by 20260730-142533's retro. Its DECISION.md rejected building this
  alongside the structural gate: a live runner is credential-bound,
  non-deterministic, cannot run inside `nix flake check`, and shipping it
  half-exercised behind a flag hides it.
- Only worth doing if the manual pass proves tedious enough to repeat. Ask the
  user before planning; a one-off manual confirmation may be the right answer
  forever.
- The structural half stays the gate either way. This would be an opt-in
  `--live` mode or a separate runner, never a `nix flake check` derivation.
- Parent Epic: 20260730-153122.
