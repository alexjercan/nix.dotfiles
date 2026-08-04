# Investigate encrypted secrets management (sops-nix vs agenix)

- PRIORITY: 40
- TAGS: chore, nix, security
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE

## Story

As the maintainer, I want a documented, encrypted-in-repo secrets mechanism so
that when a second machine or a public repo needs real secrets, the approach is
already chosen and understood. Today secrets ride in via `environmentFile`
pointing at a file OUTSIDE the store (home/alex/default.nix, scufris
`environmentFile`) - store-safe and pragmatic, but nothing is encrypted in the
repo and there is no key-rotation story.

I have no prior experience with sops-nix/agenix, so this task is
learn-and-document first, adopt-if-warranted second.

## Steps

- [x] Compare sops-nix vs agenix for this repo (age keys, host keys, home-manager
      integration, standalone home-manager on the Ubuntu box).
- [x] Write up the tradeoff and a recommendation (short doc / RETRO).
      See RECOMMENDATION.md in this task folder.
- [x] Optional PoC (migrate ONE secret, e.g. scufris env) dispositioned:
      deferred to a separate opt-in user gate rather than done in this task;
      the concrete PoC shape and open risks are documented in RECOMMENDATION.md.

## Notes

- Keep the current `environmentFile`-outside-store pattern working until a PoC
  proves the replacement.
- Standalone home-manager on non-NixOS (Ubuntu) constrains options - a host SSH
  key may not exist there; factor that in.

## Definition of Done

No Definition of Done was recorded when this task ran. The section is added on
2026-07-30 so the record satisfies the tatr v2 schema; nothing is reconstructed
after the fact.

- The work delivered and the verification the closing session ran are recorded
  in the sections above (manual: read this record).
- The task was accepted by its review (manual: read the round verdicts in
  REVIEW.md).
