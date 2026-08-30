# Review shared speech-to-text API integration

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: review

## Goal

Review whether Pi and Scufris can consume `ai-tools-api` instead of owning separate Whisper servers. Do not change product code.

## Outcome

See [REPORT.md](REPORT.md).

- Pi is directly compatible through `pi-voice-stt`'s OpenAI-compatible provider.
- Scufris needs one small multipart contract change before its endpoint can move.
- The API should become the sole owner of Whisper, its model, and port 10301.
- Scufris TTS is a valid later consolidation target.
- No other current speech inference consumers were found under `~/personal`.

## Evidence

Reviewed the three repositories, installed Pi extension documentation, the pinned `pi-voice-stt` 0.6.0 package source from the local npm cache, current Home Manager composition, and live user services/listeners.

## Follow-up: disable the deployed Scufris release

Kept the pinned input, Home Manager module import, and complete Scufris configuration. Set only `programs.scufris.enable = false` so a later compatible `v0.*` release can reactivate the existing integration.

Verification:

- Canonical evaluation reports `programs.scufris.enable = false`.
- Canonical evaluation contains no `scufris*` user units.
- `nix build .#homeConfigurations.alex.activationPackage --no-link` passed.
- Alejandra and `git diff --check` passed.
- No Home Manager activation was run.

## Follow-up: add the ai-tools-api input

Added `github:alexjercan/ai-tools-api/v0.1.0` as a root flake input. Shared `nixpkgs`, `flake-parts`, and Home Manager inputs follow the root graph. The lock resolves the annotated release tag to commit `eb0007f3bcdc29fc169268f181f159c636a60ab1`.

This step only adds and locks the input. It does not import its Home Manager module or enable its services.

Verification:

- Lock metadata confirms the repository, `v0.1.0` ref, exact release commit, and follows.
- Canonical Home Manager evaluation still succeeds.
- Alejandra and `git diff --check` passed.

## Follow-up: deploy ai-tools-api and route Pi STT

Kept the API deployment with its current consumer in `home/modules/agents/default.nix`. The agents composition imports the upstream `v0.1.0` Home Manager module, enables `services.ai-tools-api`, and otherwise keeps its service defaults: loopback API port 10300 and private Whisper port 10301.

The same composition now owns the complete Pi STT route:

- Removed `localWhisper.enable = true` so Pi no longer creates a second server.
- Kept the Pi extension, FFmpeg capture, keybind, and cleanup behavior.
- Configured its OpenAI-compatible provider at `http://127.0.0.1:10300/v1/audio/transcriptions` with `model=whisper-1` and language auto.

No separate local `ai-tools-api` module or Alex-level import remains.

Verification:

- Canonical evaluation reports the API enabled with default host and ports.
- Pi local Whisper evaluates false and the generated provider uses the public API route.
- Only `ai-tools-api.service` and `ai-tools-api-whisper.service` are generated among speech services; the old Pi and Scufris Whisper units are absent.
- `nix build .#homeConfigurations.alex.activationPackage --no-link` passed, including the API, Piper, service units, and generated Pi STT configuration.
- Alejandra and `git diff --check` passed.
- No Home Manager activation was run.
