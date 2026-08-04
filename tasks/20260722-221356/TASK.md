# Replace PoC dummy with real SCUFRIS_TELEGRAM_BOT_TOKEN sops secret

- PRIORITY: 45
- TAGS: nix, security
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE

## Story

The sops-nix PoC (20260722-214112) committed a DUMMY
`SCUFRIS_OPENAI_API_KEY=sops-poc-placeholder`. The real scufris env
(`~/.config/scufris/env`) actually holds a single variable `SCUFRIS_TELEGRAM_BOT_TOKEN`.
Replace the dummy with the real, sops-encrypted `SCUFRIS_TELEGRAM_BOT_TOKEN` value and
fix the home-manager wiring to use that variable name, so the encrypted secret
matches what scufris actually consumes. User explicitly authorized the real
secret entering (encrypted) git history (2026-07-22).

## Steps

- [x] Re-encrypt `secrets/scufris.env` from the real `~/.config/scufris/env`
      (single var `SCUFRIS_TELEGRAM_BOT_TOKEN`) as a sops dotenv; never print the
      plaintext token; confirm the committed file is ENC[...] before staging.
- [x] Update `home/alex/default.nix`: rename the sops secret and template
      variable from `SCUFRIS_OPENAI_API_KEY` to `SCUFRIS_TELEGRAM_BOT_TOKEN` (secret
      name, `sops.placeholder`, and the template line).

## Definition of Done

- The committed secret shows `SCUFRIS_TELEGRAM_BOT_TOKEN=ENC[...]` (encrypted,
  real variable name) and NOT `SCUFRIS_OPENAI_API_KEY` and NOT any plaintext
  token (cmd: `git show HEAD:secrets/scufris.env`).
- The flake evaluates (cmd: `nix flake check --no-build`).
- The home config builds
  (cmd: `nix build .#homeConfigurations.alex.activationPackage --no-link`).
- Decrypting the file yields a `SCUFRIS_TELEGRAM_BOT_TOKEN=` line with a
  non-empty value, verified by a non-printing check (e.g. grep -c) rather than
  by echoing the token (test: `sops decrypt`).
- scufris starts with the real token from the decrypted env file (manual: user
  runs `home-manager switch` and confirms).

## Notes

- Real secret: do NOT echo the token into logs/output; verify by structure
  (variable name present, value non-empty, file encrypted), never by printing.
- Keep the old plaintext `~/.config/scufris/env` in place as the fallback until
  the user switches; do not delete it.
