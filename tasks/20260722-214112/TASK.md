# PoC: migrate scufris env to sops-nix (dummy secret)

- STATUS: OPEN
- PRIORITY: 40
- TAGS: chore,nix,security

## Story

Proof-of-concept for the sops-nix recommendation (see task 20260722-113105,
tasks/20260722-113105/RECOMMENDATION.md). Wire sops-nix into the flake and
migrate the scufris `environmentFile` secret to an encrypted-in-repo sops
dotenv file, using a DEDICATED passwordless age key and a DUMMY placeholder
value (no real API key enters git history). Prove the mechanism at the repo's
own check-suite level; the live `home-manager switch`, swapping in the real
value, and restarting scufris are the user's final adoption steps, out of scope
here.

## Steps

- [ ] Add the `sops-nix` flake input (inputs.nixpkgs.follows) to `flake.nix`
      and its home-manager module to the modules list in
      `flake/home-configurations.nix`.
- [ ] Generate a dedicated passwordless age key on this machine at
      `~/.config/sops/age/keys.txt` (out of the repo and the store), reusing it
      if it already exists; record its age PUBLIC key.
- [ ] Add `.sops.yaml` at the repo root with a creation rule for
      `secrets/scufris.env` listing that age public key as the recipient.
- [ ] Encrypt `secrets/scufris.env` as a sops DOTENV file whose only value is a
      DUMMY `SCUFRIS_OPENAI_API_KEY=sops-poc-placeholder`; commit the ciphertext
      (values encrypted, keys/structure readable).
- [ ] Wire `home/alex/default.nix`: set `sops.age.keyFile`, declare the dotenv
      secret, order the scufris systemd USER service
      `Unit.After = [ "sops-nix.service" ]` (determine its exact unit name), and
      repoint `programs.scufris.environmentFile` at the decrypted secret path.
      Leave a comment documenting the old plaintext path as the fallback until
      the user switches.

## Definition of Done

- cmd: `nix flake check --no-build` passes on the branch.
- cmd: `sops -d secrets/scufris.env` prints `SCUFRIS_OPENAI_API_KEY=sops-poc-placeholder`
       (encrypt/decrypt round-trip works with the dedicated age key).
- cmd: the home-manager config for `alex` builds
       (`nix build .#homeConfigurations.alex.activationPackage --no-link`).
- manual: user runs `home-manager switch`, swaps the dummy for the real value in
          `secrets/scufris.env` via `sops`, and confirms scufris starts and
          authenticates from the decrypted env file.

## Notes

- DUMMY value only - the real `SCUFRIS_OPENAI_API_KEY` must NOT enter git
  history in this PoC.
- Keep the current `~/.config/scufris/env` plaintext file in place as the
  fallback until the user has switched and verified; do not delete it here.
- No `home-manager switch` and no service restart from this task - live-system
  changes are the user's call.
