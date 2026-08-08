# flow skill: codify umbrella/GOAL lifecycle (close, residue, no-RETRO)

- STATUS: CLOSED
- PRIORITY: 60
- TAGS: feature, flow

## Story

As a flow user, I want the flow skill to codify the umbrella/GOAL task
lifecycle, so that umbrella close-out is not improvised each time (as it was
during the v2 adoption wave). Cover: when a GOAL closes, how residue/unresolved
findings get dispositioned, and that the umbrella itself carries no RETRO.

## Steps

- [x] Review how umbrellas were handled in nix.dotfiles GOAL.md tasks and the v2 adoption wave (39 unresolved findings awaiting rulings).
- [x] Add explicit flow skill guidance: umbrella close condition, residue disposition options, no-RETRO-by-design for umbrellas.
- [x] Ensure `tatr check` / conformance expectations align (umbrella tasks should not be flagged for missing RETRO).
- [x] Deploy and confirm (nix flake check --no-build green).

## Definition of Done

- Flow skill documents the umbrella lifecycle end to end (manual: reviewer reads the new section).
- The umbrella-lifecycle guidance is generic and internally consistent (cmd: `grep -n "no REVIEW.md or RETRO.md" home/modules/agents/skills/flow/SKILL.md`).
- Plain conformance stays clean (cmd: `tatr check`). NOTE: strict `tatr check -S` exemption for `goal`-tagged umbrellas is tatr task 20260720-220046, not this doc task; DoD amended during work (see RETRO).

## Notes

- Related to tatr task #5 (historical/no-retro recognition) - align the two.
