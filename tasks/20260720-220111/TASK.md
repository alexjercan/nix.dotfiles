# flow skill: codify umbrella/GOAL lifecycle (close, residue, no-RETRO)

- STATUS: OPEN
- PRIORITY: 60
- TAGS: feature,flow

## Story

As a flow user, I want the flow skill to codify the umbrella/GOAL task
lifecycle, so that umbrella close-out is not improvised each time (as it was
during the v2 adoption wave). Cover: when a GOAL closes, how residue/unresolved
findings get dispositioned, and that the umbrella itself carries no RETRO.

## Steps

- [ ] Review how umbrellas were handled in nix.dotfiles GOAL.md tasks and the v2 adoption wave (39 unresolved findings awaiting rulings).
- [ ] Add explicit flow skill guidance: umbrella close condition, residue disposition options, no-RETRO-by-design for umbrellas.
- [ ] Ensure `tatr check` / conformance expectations align (umbrella tasks should not be flagged for missing RETRO).
- [ ] Deploy and confirm.

## Definition of Done

- Flow skill documents the umbrella lifecycle end to end (manual: reviewer reads the new section).
- Umbrella tasks do not trip retro-completeness expectations (cmd: `tatr check -S` clean on a closed umbrella).

## Notes

- Related to tatr task #5 (historical/no-retro recognition) - align the two.
