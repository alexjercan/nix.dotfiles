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
- [x] 20260722-214112 (p40, nix.dotfiles) PoC: migrate scufris env to sops-nix (dummy secret)
      user opted in at the PoC gate (2026-07-22); sops-nix chosen, dummy value only.
      landed 2004344; 1 review round (out-of-context, APPROVE). Wiring proven at
      eval/build level (flake check, HM build, sops decrypt, After ordering);
      live switch is the user's adoption step.
- [ ] 20260722-220536 (p40, nix.dotfiles) Add secrets/README.md multi-machine key runbook
      user request mid-flow (2026-07-22): document how to decrypt on a new machine.

## Manual acceptance (batched for the user at Finish)

- (pending) 20260722-113105: confirm the recommendation is sound and the
  tradeoff writeup covers the standalone-HM-on-Ubuntu constraint.
- (resolved) PoC gate: user opted IN (2026-07-22) - sops-nix PoC done with a
  dummy value, landed 2004344.
- (pending) 20260722-214112 adoption: run `home-manager switch`, swap the dummy
  for the real value via `sops secrets/scufris.env`, and confirm scufris starts
  and authenticates from the decrypted env file. (Live-system + secret step,
  left to the user by design.)
