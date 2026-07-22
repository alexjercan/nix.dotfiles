# Review: Add secrets/README.md multi-machine key runbook

- TASK: 20260722-220536
- BRANCH: docs/secrets-readme

## Round 1

- VERDICT: APPROVE
- REVIEWER: out-of-context

The out-of-context reviewer independently re-ran the full rekey dry-run
(encrypt to key A, `sops updatekeys --yes` by A to add B, decrypt with B alone),
confirmed the README's example public key is byte-for-byte the recipient in the
real `.sops.yaml` and `secrets/scufris.env`, that the `.sops.yaml` structure
matches, that no real secret leaks (only the safe public age key), and that
`nix flake check --no-build` still passes (README not matched by the
`secrets/*.env` sops rule). The in-session pass had already dry-run-verified the
same rekey flow before writing the runbook. Both findings were addressed.

- [x] R1.1 (MINOR) secrets/README.md - the onboarding `age-keygen -o` step
  lacked a note that age-keygen refuses to overwrite an existing key; a confused
  reader might `rm` the key and lock themselves out.
  - Response: Fixed - added a note that `-o` refuses to overwrite (safe), to
    reuse the existing key, and to never `rm` it.
- [x] R1.2 (NIT) secrets/README.md - commands mix `../.sops.yaml` (README-relative)
  with `secrets/scufris.env` (repo-root-relative).
  - Response: Fixed - added a line stating the sops commands are run from the
    repo root, where the secret paths are relative.

No secret leak; no dangerous command. All Steps honestly done. This task has no
open manual: DoD items.
