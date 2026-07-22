# Review: Investigate sops-nix vs agenix, write recommendation

- TASK: 20260722-113105
- BRANCH: chore/secrets-research

## Round 1

- VERDICT: APPROVE
- REVIEWER: out-of-context

The out-of-context reviewer verified the diff is docs/task-records only, that
`nix flake check --no-build` still passes, that the grounding claims match this
repo (scufris HM user service + environmentFile at home/alex/default.nix:127,
HM module imported at :186, standalone homeManagerConfiguration at
flake/home-configurations.nix:17), and that every load-bearing agenix/sops-nix
claim holds against the authoritative READMEs. The in-session pass independently
re-verified the grounding claims (scufris is `inputs.scufris.homeManagerModules.default`,
not a NixOS service; the Ubuntu target is standalone HM with no host key) before
adopting. Spec: Steps 1-2 delivered and honestly ticked; Step 3 (PoC) honestly
deferred with a documented shape and open risks. No material omission that would
flip the recommendation. Both findings below are NITs and were addressed.

- [x] R1.1 (NIT) RECOMMENDATION.md - agenix HM decrypt path was stated only as
  "a configured path (HM)"; name the default for parity with the sops-nix path.
  - Response: Fixed - now states `$XDG_RUNTIME_DIR/agenix` on Linux by default
    (configurable).
- [x] R1.2 (NIT) RECOMMENDATION.md - the agenix runner-up case should note the
  `age.identityPaths` "required, no default" point is symmetric once you commit
  to a dedicated age key, so the reader does not over-weight it against agenix.
  - Response: Fixed - added a half-sentence in the "Choose agenix instead if"
    paragraph making the symmetry explicit.

Pending user checks (manual: DoD items, cleared at flow Finish):
- Confirm the recommendation is sound and the tradeoff writeup covers the
  standalone-HM-on-Ubuntu constraint.
