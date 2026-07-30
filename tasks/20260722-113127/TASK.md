# Investigate nixvim not following nixpkgs

- STATUS: CLOSED
- PRIORITY: 35
- TAGS: chore,nix
- KIND: TASK
- FLOW STEP: DONE
- PLAN STATUS: APPROVED

## Story

Every one of my own flake inputs uses `inputs.nixpkgs.follows = "nixpkgs"`, but
`nixvim` (flake.nix) does NOT, so it drags its own nixpkgs into the closure.
This may be intentional (nixvim's docs sometimes recommend not following, for
binary-cache hits) or an oversight. I want a deliberate decision, not an
accident.

## Steps

- [x] Check nixvim's own guidance on `follows` (cache hits vs closure size).
- [x] Measure the closure/eval impact of following vs not.
- [x] Decide: add `inputs.nixpkgs.follows = "nixpkgs"` to nixvim, or leave it and
      add a one-line comment saying why.

## Resolution

Decision: LEAVE nixvim un-followed; document why (done, comment added in flake.nix).

- Upstream guidance is explicit (nixvim install guide): "We recommend against
  using `inputs.nixpkgs.follows = \"nixpkgs\";` on the `nixvim` input as we test
  Nixvim against our Nixpkgs revision. When you use `follows` you opt out of
  guarantees provided by these tests."
- Measured drift: root nixpkgs tracks `nixos-unstable` (rev b5aa0fb); nixvim's
  own nixpkgs (`nixpkgs_2` in flake.lock) tracks a different branch,
  `nixpkgs-unstable` (rev 3e41b24). Following would swap nixvim onto the
  untested nixos-unstable rev.
- Cost of not following is a second nixpkgs in the eval (eval time + some store
  duplication), accepted in exchange for staying on nixvim's validated rev.

## Notes

- Whatever the outcome, the input should carry a comment so the inconsistency
  reads as intentional. (Done.)

## Definition of Done

No Definition of Done was recorded when this task ran. The section is added on
2026-07-30 so the record satisfies the tatr v2 schema; nothing is reconstructed
after the fact.

- The work delivered and the verification the closing session ran are recorded
  in the sections above (manual: read this record).
- The task was accepted by its review (manual: read the round verdicts in
  REVIEW.md).
