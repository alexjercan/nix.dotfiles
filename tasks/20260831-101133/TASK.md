# Deploy Scufris v2.0.0

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: scufris, deployment

## Goal

Pin immutable Scufris `v2.0.0`, activate the strict protocol-v5 service,
gateway, agent, and desktop together, and verify the private production API
without exposing credentials or attachment content.

## Acceptance

- The Scufris input names tag `v2.0.0` and resolves to release commit
  `69831c35aa19436892d44a25cd3283baad41e0d9`.
- Repository checks and the Home Manager activation package build pass.
- Service, desktop, gateway, Tailscale Serve, and ai-tools-api units are active.
- The gateway listens only on loopback.
- Authenticated production health, protocol-v5 WSS registration, and bounded
  attachment transfer pass without printing token or object content.
- The v2.0.0 iOS build is uploaded after coordinated host activation.

## Verification

- The input names `v2.0.0` and `flake.lock` resolves Scufris commit
  `69831c35aa19436892d44a25cd3283baad41e0d9`.
- Alejandra, `nix flake check -L`, and
  `.#homeConfigurations.alex.activationPackage` passed.
- Home Manager activation stopped and restarted the desktop, service, and
  gateway as one coordinated protocol replacement.
- `scufris-service`, `scufris-desktop`, `scufris-surface-gateway`,
  `scufris-tailscale-serve`, `ai-tools-api`, and `ai-tools-api-whisper` are
  active. The three Scufris executables report version 2.0.0.
- The gateway listens only on `127.0.0.1:10440`, and Tailscale Serve maps only
  the production root to that listener.
- Authenticated production health and protocol-v5 WSS registration passed.
- A generated non-user text object completed authenticated upload and download;
  the verification compared bytes without printing the token, ID, or content.
- An explicit service restart left the gateway active and preserved
  authenticated production health.
- TestFlight `2.0.0 (12)` uploaded successfully in run `33367784970` from the
  immutable release commit.
