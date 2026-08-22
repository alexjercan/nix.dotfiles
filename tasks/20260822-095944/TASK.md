# Deploy Scufris v0.1.0 release input

- STATUS: CLOSED
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

## Implementation evidence

- Replaced only the temporary `git+file` source with
  `github:alexjercan/scufris2/v0.1.0`.
- Preserved all Scufris input follows and the public Home Manager module wiring.
- Refreshed only the Scufris lock node. It records owner `alexjercan`, repository
  `scufris2`, original ref `v0.1.0`, and locked revision
  `96763cc4ea90e6fd43cf6b90ada64dc49d0ab561` with type `github`.
- Updated the exact revision check and derivation name to identify v0.1.0.
- Repository scans found no machine-local Scufris source in `flake.nix` or
  `flake.lock`.

## Verification evidence

- Focused `scufris-revision`, `home-module`, and `scufris-popup` builds passed.
- `nix flake check` passed, including voice STT, local Whisper, Scufris popup,
  exact revision, agent Home Manager module, and all other flake checks.
- `nix build .#homeConfigurations.alex.activationPackage --no-link` passed.
- `git diff --check` passed.
- Implementation revision: `2e73548`.
- `sprout sync deploy-scufris-v0-1` passed after the implementation commit; the
  branch was already up to date.
- Post-sync focused checks, full flake check, activation-package build, lock
  assertions, local-source scan, and whitespace check passed.
- No Home Manager activation was run.
