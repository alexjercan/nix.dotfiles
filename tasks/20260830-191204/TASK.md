# Deploy Scufris v1.1.0

- STATUS: OPEN
- PRIORITY: 100
- TAGS: scufris, deployment

## Goal

Pin the immutable Scufris v1.1.0 release commit, activate it for the current
Home Manager profile, and verify the private remote API without exposing
credentials or user content.

## Acceptance

- The Scufris input resolves to release commit
  `07a4f776010370368d6cbc1ec47796f7856cf835`.
- Repository checks pass before activation.
- Service, desktop, gateway, Tailscale Serve, and ai-tools-api units are active.
- The gateway listens only on loopback.
- Authenticated production WSS and HTTPS health/transcription routes work
  through Tailscale Serve. Verification never prints the token, audio, or
  transcript text.
