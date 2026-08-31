# Deploy Scufris v2.1.0

- STATUS: OPEN
- PRIORITY: 100
- TAGS: scufris,deployment

## Goal

Pin immutable Scufris `v2.1.0` and activate it. The release adds the morning
briefing and changes how the service handles an answer nobody asked for.

## Acceptance

- The Scufris input names tag `v2.1.0` and resolves to release commit
  `9e2f1fa83523eeeaa7a802062d27305b404c2c03`.
- `nix flake check -L` and the Home Manager activation package build pass.
- Service, desktop, and gateway units are active after activation, and the
  three Scufris executables report version 2.1.0.
- A morning briefing collects from the declaring projects and reaches the
  conversation window rather than being refused.

## Verification
