# Add secrets/README.md multi-machine key runbook

- STATUS: IN_PROGRESS
- PRIORITY: 40
- TAGS: docs, nix, security

## Story

The sops-nix PoC (task 20260722-214112) left the multi-machine / key-rotation
mechanics implicit in `.sops.yaml` comments and RECOMMENDATION.md. Add a
`secrets/README.md` runbook, next to the encrypted secret, that documents how to
decrypt on a NEW machine (per-machine age key + rekey), how to add/revoke a
recipient, and the lock-yourself-out gotchas. The commands must be VERIFIED in a
throwaway scratch dir before being written (a wrong `sops updatekeys` invocation
could mislead someone into an unrecoverable state).

## Steps

- [x] Dry-run the full "add a machine" flow in a scratch dir: generate two age
      keys, encrypt a dummy dotenv to key A, `sops updatekeys` to add key B, and
      confirm key B alone can decrypt. Capture the exact working commands.
- [x] Write `secrets/README.md`: per-machine-key model, onboarding a new machine
      (generate key, add recipient, `sops updatekeys`, pull + switch), the
      chicken-and-egg (a new key cannot self-bootstrap), key-loss / backup
      recipient advice, and revoking a machine. Use the verified commands and
      reference the real `.sops.yaml` anchors.

## Definition of Done

- test: the scratch dry-run proves key B (added via `sops updatekeys`) decrypts
        a secret originally encrypted only to key A.
- cmd: `nix flake check --no-build` still passes (the new README is not matched
       by the `secrets/*.env` rule, so sops-nix ignores it).
- cmd: `test -f secrets/README.md` and it names `sops updatekeys`, `age-keygen`,
       and the new-machine onboarding steps.

## Notes

- Documentation only; no secret values, no runtime change.
- Keep it terse and copy-pasteable - a runbook, not an essay.
