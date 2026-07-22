# Investigate nixvim not following nixpkgs

- STATUS: CLOSED
- PRIORITY: 35
- TAGS: chore, nix

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
