# Deploy the Scufris iOS surface gateway

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: scufris, ios

## Goal

Replace the proven transient iOS surface gateway with a persistent Home Manager
unit while retaining the existing private token and Tailscale Serve endpoint.

## Scope

- Pin the exact Scufris revision that contains the authenticated WSS gateway and
  iOS text client.
- Migrate the deployment from the one-release Home Manager aliases to the
  current top-level agent and API options.
- Enable `service.remoteSurface` on loopback port 10440 with the existing
  private token file.
- Extend composition checks to prove the gateway unit and bounded arguments.
- Build and activate the Home Manager generation, then remove the transient
  unit without interrupting the iOS conversation.

## Decisions

- Keep Tailscale Serve as the persistent tailnet-only TLS proxy.
- Keep the bearer token outside the Nix store under the user's private data
  directory.
- Pin an immutable commit until these post-v0.6 changes receive a release tag.

## Verification

- The lock resolves immutable Scufris revision
  `abaa75c6350e9062e1bedb29d443c090de5ae7f4` and still follows the root
  `ai-tools-api` input.
- All eight `nix flake check` checks passed.
- `nix build .#homeConfigurations.alex.activationPackage --no-link` passed.
- `home-manager switch --flake .#alex` passed and replaced the transient
  gateway without changing the Tailscale Serve root route.
- `scufris-service`, `scufris-desktop`, `scufris-surface-gateway`,
  `ai-tools-api`, and `ai-tools-api-whisper` are active.
- The gateway unit is persistent, listens only on `127.0.0.1:10440`, reads the
  mode-0600 token, and completed an authenticated WSS protocol handshake after
  activation.
- Before persistence, the physical iPhone replayed the conversation, submitted
  text, and displayed the assistant response through the same URL and token.
