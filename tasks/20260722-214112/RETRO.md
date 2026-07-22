# Retro: PoC - migrate scufris env to sops-nix (dummy secret)

- TASK: 20260722-214112
- BRANCH: chore/sops-nix-poc (landed 2004344)
- REVIEW ROUNDS: 1 (out-of-context, APPROVE)

## What went well

- Verified the whole sops-nix wiring at the repo's own check-suite level
  (flake check + HM activationPackage build + sops decrypt round-trip + `nix
  eval` of the generated `After` list and `environmentFile` path) WITHOUT a live
  `home-manager switch`. The switch is disruptive and the user's call; proving
  correctness by evaluation kept the PoC safe and still convincing.
- Grounded the systemd `After` ordering on the REAL unit name by evaluating
  `config.systemd.user.services` before writing it (found `scufris`), so the
  ordering merged with the module's own `network.target` instead of guessing.
- Dummy-value-only kept the real API key out of permanent git history while
  still exercising the full encrypt/decrypt/template path.

## What went wrong

- First instinct would have been to run `nix flake check` right after writing
  `${inputs.self}/secrets/scufris.env`, but a flake resolves `inputs.self`
  against the GIT tree - an untracked new file is invisible and eval fails on a
  missing path. Avoided only because the secret was `git add`ed before checking.
  Root cause: `${inputs.self}/<path>` sees tracked state, not the working tree.

## What to improve next time

- When a new file is referenced via `${inputs.self}/...`, `git add` it BEFORE
  the first `nix flake check`/build, or expect a missing-path eval error.

## Action items

- [x] Added ledger lesson `inputs-self-needs-tracked-file`.
- [ ] Adoption (user, not code): `home-manager switch`, swap the dummy for the
      real value via `sops secrets/scufris.env`, confirm scufris authenticates.
      Tracked as the umbrella's manual-acceptance item.
