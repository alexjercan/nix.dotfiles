# Replace PoC dummy with real TELEGRAM_BOT_TOKEN sops secret

- STATUS: IN_PROGRESS
- PRIORITY: 45
- TAGS: nix, security

## Story

The sops-nix PoC (20260722-214112) committed a DUMMY
`SCUFRIS_OPENAI_API_KEY=sops-poc-placeholder`. The real scufris env
(`~/.config/scufris/env`) actually holds a single variable `TELEGRAM_BOT_TOKEN`.
Replace the dummy with the real, sops-encrypted `TELEGRAM_BOT_TOKEN` value and
fix the home-manager wiring to use that variable name, so the encrypted secret
matches what scufris actually consumes. User explicitly authorized the real
secret entering (encrypted) git history (2026-07-22).

## Steps

- [x] Re-encrypt `secrets/scufris.env` from the real `~/.config/scufris/env`
      (single var `TELEGRAM_BOT_TOKEN`) as a sops dotenv; never print the
      plaintext token; confirm the committed file is ENC[...] before staging.
- [x] Update `home/alex/default.nix`: rename the sops secret and template
      variable from `SCUFRIS_OPENAI_API_KEY` to `TELEGRAM_BOT_TOKEN` (secret
      name, `sops.placeholder`, and the template line).

## Definition of Done

- cmd: `git show HEAD:secrets/scufris.env` shows `TELEGRAM_BOT_TOKEN=ENC[...]`
       (encrypted, real variable name) and NOT `SCUFRIS_OPENAI_API_KEY` and NOT
       any plaintext token.
- cmd: `nix flake check --no-build` passes.
- cmd: the home config builds (`nix build .#homeConfigurations.alex.activationPackage --no-link`).
- test: `sops decrypt` of the file yields a `TELEGRAM_BOT_TOKEN=` line with a
        non-empty value (verified via a non-printing check, e.g. grep -c, not by
        echoing the token).
- manual: user runs `home-manager switch` and confirms scufris starts with the
          real token from the decrypted env file.

## Notes

- Real secret: do NOT echo the token into logs/output; verify by structure
  (variable name present, value non-empty, file encrypted), never by printing.
- Keep the old plaintext `~/.config/scufris/env` in place as the fallback until
  the user switches; do not delete it.
