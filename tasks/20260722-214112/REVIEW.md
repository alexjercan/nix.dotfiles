# Review: PoC - migrate scufris env to sops-nix (dummy secret)

- TASK: 20260722-214112
- BRANCH: chore/sops-nix-poc

## Round 1

- VERDICT: APPROVE
- REVIEWER: out-of-context

The out-of-context reviewer ran all three DoD `cmd:` proofs itself (flake check,
sops decrypt round-trip, HM activationPackage build - all pass), confirmed the
sops-nix HM API usage is correct, that `environmentFile` resolves to the
rendered template path, that `scufris.service` `After` merges to
`["sops-nix.service" "network.target"]` without clobbering the module's own
ordering, and that the secret is encrypted with only a dummy value while the age
PRIVATE key is not tracked. The in-session pass independently re-verified the
security claim: `git ls-files` tracks no age private key, the committed
`secrets/scufris.env` value is `ENC[AES256_GCM,...]`, and a diff scan finds no
real key patterns. All Steps honestly ticked; the `manual:` DoD (switch + real
value swap + restart) is a pending user check, correctly out of scope.

Both findings are NITs; neither warrants a change for the PoC (rationale in
Responses).

- [ ] R1.1 (NIT) home/alex/default.nix - declaring `sops.secrets."SCUFRIS_OPENAI_API_KEY"`
  also writes a standalone decrypted copy at ~/.config/sops-nix/secrets/, beside
  the rendered template.
  - Response: Won't-fix (inherent). sops-nix templates require the secret to be
    declared to expose `sops.placeholder`; there is no placeholder without the
    secret. The extra decrypted file is runtime-only, outside the store, and
    harmless. Accepted as-is for the PoC.
- [ ] R1.2 (NIT) .sops.yaml - `path_regex: secrets/[^/]+\.env$` is broader than
  the single named file.
  - Response: Intentional. A path-scoped rule for `secrets/*.env` is the
    forward-looking recipient policy the recommendation calls for (adding a
    secret should not need a new rule). Kept.

Pending user checks (manual: DoD, cleared at flow Finish / adoption):
- Run `home-manager switch`, swap the dummy for the real value via
  `sops secrets/scufris.env`, and confirm scufris starts and authenticates from
  the decrypted env file.
