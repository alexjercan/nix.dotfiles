# Deploy Scufris v2.0.0

- STATUS: OPEN
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

Pending.
