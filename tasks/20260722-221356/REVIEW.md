# Review: Replace PoC dummy with real TELEGRAM_BOT_TOKEN sops secret

- TASK: 20260722-221356
- BRANCH: fix/real-telegram-secret

## Round 1

- VERDICT: APPROVE
- REVIEWER: out-of-context

No findings. The out-of-context reviewer confirmed the rename is consistent
across the sops secret, `sops.placeholder`, and template (all `TELEGRAM_BOT_TOKEN`,
no leftover `SCUFRIS_OPENAI_API_KEY`); that the committed `secrets/scufris.env`
is genuinely encrypted (`TELEGRAM_BOT_TOKEN=ENC[...]`, 0 dummy/old-name
occurrences); that a non-printing decrypt round-trip yields a non-empty value
(length 46) without ever echoing the token; that no plaintext token leaks in the
diff, comments, TASK.md, README, or commit message; that the stale "DUMMY" wording
was removed; that the plaintext fallback is not deleted; and that flake check +
HM activationPackage build both pass. The in-session pass had independently
verified the encryption, rename, and build before the round.

No open findings; no manual: DoD item is the reviewer's to resolve - the user's
`home-manager switch` + start confirmation remains a pending user check.

Pending user check (manual: DoD):
- Run `home-manager switch` and confirm scufris starts with the real
  TELEGRAM_BOT_TOKEN from the decrypted env file.
