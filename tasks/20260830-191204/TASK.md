# Deploy Scufris v1.1.0

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: scufris, deployment

## Goal

Pin the immutable Scufris `v1.1.0` release tag, activate it for the current
Home Manager profile, and verify the private remote API without exposing
credentials or user content.

## Acceptance

- The Scufris input names tag `v1.1.0` and resolves to release commit
  `07a4f776010370368d6cbc1ec47796f7856cf835`.
- Repository checks pass before activation.
- Service, desktop, gateway, Tailscale Serve, and ai-tools-api units are active.
- The gateway listens only on loopback.
- Authenticated production WSS and HTTPS health/transcription routes work
  through Tailscale Serve. Verification never prints the token, audio, or
  transcript text.

## v1.1.1 lifecycle follow-up

The reusable Scufris module now makes the service want the enabled gateway.
Pin v1.1.1, activate it, and prove an explicit service restart leaves both units
active.

## Verification

- `nix flake check -L` passed against the immutable v1.1.0 release commit.
- Home Manager activation completed and restarted the service, desktop,
  gateway, and Tailscale Serve units.
- `scufris-service`, `scufris-desktop`, `scufris-surface-gateway`,
  `scufris-tailscale-serve`, `ai-tools-api`, and `ai-tools-api-whisper` are
  active.
- The deployed gateway listens only on `127.0.0.1:10440`.
- Authenticated production `GET /health` and protocol-v4 WSS registration pass.
- A generated non-user speech sample completed authenticated host transcription
  through production HTTPS. The check inspected only the bounded response shape
  and did not print its text.
- v1.1.1 is pinned and active. An explicit service restart restarted the
  gateway, left both units active, and preserved authenticated production
  health.
