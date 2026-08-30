# Update Scufris to 0.6.0

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: scufris

## Goal

Deploy Scufris v0.6.0 against the existing shared `ai-tools-api` v0.1.1 service.

## Decisions

- Follow the root `ai-tools-api` input so Scufris and the existing provider use
  one package graph.
- Enable the v0.6.0 launcher, background service, desktop, and speech.
- Use the configured Pi package as the supervised agent package.
- Set `desktop.aiToolsApi.manage = false` and consume loopback port 10300 so
  Scufris cannot start a competing inference service.
- Remove deprecated `voice`, `desktop.stt`, and top-level `piPackage` paths.

## Verification

- `alejandra --check` passed for all changed Nix files.
- `nix flake check` passed all seven checks.
- `nix build .#homeConfigurations.alex.activationPackage --no-link` passed.
- Evaluation resolved Scufris to release commit
  `d757b951ef03bfe8cca0201373f8c19fd24f4901` and followed the root
  `ai-tools-api` input.
- The deployed module evaluates `aiToolsApi.manage = false`, the transcription
  route as `http://127.0.0.1:10300/v1/audio/transcriptions`, a packaged speech
  command, and only the existing `ai-tools-api` and `ai-tools-api-whisper`
  services.
- Replaced the stale removed-popup check with a protocol-v4 Scufris composition
  check; this also removed the dangling reference to the deleted i3 module.

