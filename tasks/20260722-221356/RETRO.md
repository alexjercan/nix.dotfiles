# Retro: Replace PoC dummy with real TELEGRAM_BOT_TOKEN sops secret

- TASK: 20260722-221356
- BRANCH: fix/real-telegram-secret (landed 3b3c131)
- REVIEW ROUNDS: 1 (out-of-context, APPROVE, no findings)

## What went well

- Handled a real secret without leaking it: copied the plaintext in, encrypted
  in place, and verified everything by STRUCTURE (variable name present, value
  ENC[...], decrypted value length non-empty) instead of ever printing the
  token. The out-of-context reviewer was explicitly told the same and confirmed
  zero leaks (the harness classifier even blocked an argv-based decrypt attempt).
- One clean review round with no findings, because the rename was verified
  consistent (secret name = placeholder = template key = dotenv key =
  TELEGRAM_BOT_TOKEN) before handing off.

## What went wrong

- The PoC (20260722-214112) invented the secret's variable name from a nearby
  code COMMENT (`SCUFRIS_OPENAI_API_KEY`, mentioned in home/alex/default.nix)
  rather than the actual `~/.config/scufris/env`, which holds a single
  `TELEGRAM_BOT_TOKEN`. So the dummy PoC used the wrong KEY name, not just a
  dummy value - this task had to fix the name too. Root cause: assumed the
  secret's shape from documentation instead of reading the secret file's keys.

## What to improve next time

- When wiring a secret, derive its variable names by reading the actual secret
  file's keys (names only), not from a comment or config that mentions a
  plausible-looking env var. A dummy PoC should still use the REAL key names.

## Action items

- [x] Added ledger lesson `read-secret-keys-not-assume`.
- (pending user) adoption unchanged: `home-manager switch` + confirm scufris
  starts with the real token.
