# Deploy Scufris v0.1.0 release input

- STATUS: OPEN
- PRIORITY: 100
- TAGS: scufris, release, deployment

## Goal

Replace the canonical machine-local Scufris source with the published `v0.1.0` GitHub release while preserving the accepted voice deployment.

## Dependency

- Published source: `github:alexjercan/scufris2/v0.1.0`.
- Release commit: `96763cc4ea90e6fd43cf6b90ada64dc49d0ab561`.
- The annotated tag resolves to that commit.

## Accepted design

- Replace the `git+file` Scufris input with the tagged GitHub input.
- Keep existing input follows and the public Home Manager interface unchanged.
- Update the lockfile from the network release source.
- Change the exact Scufris revision check to require the release commit and identify `v0.1.0` in its failure text.
- Do not change voice ownership, Whisper, Piper, popup, i3, STT, or runtime behavior.
- Review all changes before Home Manager activation.

## Verification

- Confirm the lock contains the GitHub owner, repository, tag, and exact release revision with no local Scufris URL.
- Run focused Scufris input, agent, popup, and Home Manager checks.
- Run `nix flake check`.
- Run `nix build .#homeConfigurations.alex.activationPackage --no-link`.
- Run `git diff --check`.

## Completion criteria

- Canonical evaluation and build resolve Scufris without the local repository.
- Structured review approves the dotfiles change.
- Home Manager activation passes.
- Whisper and popup services remain active.
- Super+S toggle, microphone transcription, speech playback, and session resume pass live acceptance.
