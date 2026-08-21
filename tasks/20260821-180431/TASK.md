# Align Plannotator integrations to 0.27.4

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: agents, plannotator

Align Plannotator integrations at 0.27.4 and add a focused drift check.

## Implementation

- Updated the official x86_64-linux binary release and fixed-output hash.
- Regenerated the exact Pi extension npm lock at 0.27.4.
- Refined the Plannotator smoke check to compare binary package metadata with
  lock-derived extension metadata. One version change without the other now
  fails evaluation.

## Verification

- `nix eval` reports 0.27.4 for the binary and extension.
- A temporary binary metadata mismatch fails with the expected drift message.
- `npm install --package-lock-only --ignore-scripts --legacy-peer-deps` leaves
  the regenerated lock unchanged.
- `nix build .#checks.x86_64-linux.plannotator --no-link` passes.
- `nix build .#extensions.x86_64-linux.plannotator --no-link` passes.
- `nix flake check` passes.
- `nix build .#homeConfigurations.alex.activationPackage --no-link` passes.
