# Goal: choose and document an encrypted-in-repo secrets mechanism

- DATE: 20260722
- UMBRELLA TASK: 20260722-212330
- LANDING SCOPE: squash-merge the research doc to the local `master` branch, no
  push (pushing is the user's call). The optional PoC migration is a SEPARATE
  decision gate presented to the user after the recommendation lands; it does
  not auto-proceed.

## Goal

Today the repo's only real secret (scufris `SCUFRIS_OPENAI_API_KEY` and
friends) rides in via `environmentFile = ~/.config/scufris/env`, a file kept
OUTSIDE the Nix store. That is store-safe and pragmatic but nothing is
encrypted in the repo and there is no key-rotation story. When a second machine
or a public repo needs real secrets, the approach must already be chosen and
understood.

This run delivers a grounded comparison of sops-nix vs agenix FOR THIS REPO
(one NixOS host with a host SSH key; standalone home-manager on a non-NixOS
Ubuntu box where a host key may not exist), a clear recommendation with
rationale, and - only if the user opts in after reading it - a proof-of-concept
migration of exactly one secret. The maintainer has no prior experience with
either tool, so learn-and-document comes first, adopt-if-warranted second.

## Done means

1. A comparison doc exists in the repo covering sops-nix vs agenix along the
   axes that matter here: age vs SSH keys, host-key availability on NixOS vs
   standalone HM on Ubuntu, home-manager integration (module vs standalone),
   secret-at-rest format, and key-rotation. (cmd: the doc file exists and names
   both tools and the standalone-HM/Ubuntu constraint)
2. The doc ends with an unambiguous recommendation and the reasoning behind it,
   including what stays on the current `environmentFile` pattern until a PoC
   proves the replacement. (manual: the user reads it and agrees the
   recommendation is sound and sufficiently justified)
3. The current `environmentFile`-outside-store pattern is untouched and the
   flake still evaluates. (cmd: `nix flake check --no-build`)
4. The optional PoC is dispositioned - either performed and landed as its own
   task, or explicitly deferred in this file with a reason. (manual: the user's
   decision at the PoC gate is recorded)

Overall: `nix flake check --no-build` is green and the recommendation doc is
committed on master.

## Tasks

Updated as tasks land (one line per land).

- [x] 20260722-113105 (p40, nix.dotfiles) Investigate sops-nix vs agenix, write recommendation
      landed 47dfb9b; 1 review round (out-of-context, APPROVE); recommends
      sops-nix + dedicated passwordless age key per machine (agenix a fair
      runner-up). No runtime change; flake check green.
- [ ] (conditional) PoC: migrate scufris env to the chosen tool - created only if the user opts in at the PoC gate

## Manual acceptance (batched for the user at Finish)

- (pending) 20260722-113105: confirm the recommendation is sound and the
  tradeoff writeup covers the standalone-HM-on-Ubuntu constraint.
- (pending) PoC gate: decide whether to migrate the scufris secret now as a
  proof of concept, or defer.
