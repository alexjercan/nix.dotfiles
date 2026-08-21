# Deploy local voice Scufris popup

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: voice, pi, i3, audio

## Goal

Deploy global local speech-to-text for Pi and a login-started voice-enabled Scufris Kitty scratchpad with local Piper speech.

## Accepted design

- Pin and audit `pi-voice-stt` 0.6.0 through the existing Nix npm-extension builder. Enable it for Pi generally, including Scufris.
- Keep the extension optional at the agents module boundary. No imperative `pi install` state.
- Use existing ffmpeg microphone capture with PulseAudio/PipeWire `default` input.
- Deploy a loopback-only systemd user `whisper-server` from `whisper-cpp-vulkan`.
- Pin `large-v3-turbo-q5_0` in the Nix store. Bind `127.0.0.1:10301`, expose `/inference`, use language auto, and never expose the upload service on the network.
- Configure `pi-voice-stt` as a local OpenAI-compatible provider at `http://127.0.0.1:10301/inference`, with no API key and AI transcript cleanup disabled.
- Deploy Piper 1.4.2 with pinned `en_US-lessac-medium` model and config for Scufris TTS.
- Start Scufris directly in one Kitty process at i3 login. Do not use tmux, RPC, a native frontend, or a separate Scufris daemon.
- Give Kitty an exact Scufris class/title. Move it to the i3 scratchpad, float it centered at a useful voice-assistant size, and keep it hidden after startup.
- `Super+S` toggles the Scufris scratchpad. Move full screenshot to `Print` and region screenshot to `Shift+Print`.
- Launch with `SCUFRIS_SPEECH=1`, `SCUFRIS_CALM=1`, and trusted Piper model/config environment. Use a dedicated persisted Pi session directory and resume the latest Scufris conversation on login.
- Startup and the hotkey are idempotent and do not create duplicate Kitty or Scufris processes.
- Never kill tmux or any tmux server. This workflow does not call tmux.

## Definition of done

- Normal Pi has `pi-voice-stt` with Ctrl+R recording and `/stt doctor`.
- Whisper service starts on login, stays loopback-only, loads the pinned model, and returns JSON text for a fixture WAV.
- Scufris Kitty starts once at login in the scratchpad and remains alive while hidden.
- Super+S toggles only the exact Scufris window. Screenshot bindings move as accepted.
- Popup uses a dedicated resumable conversation and speech/Calm defaults. Normal Pi and ordinary Scufris remain unchanged.
- Piper model and PipeWire playback are available to the Scufris speech helper without mutable downloads or arbitrary commands.
- Failure of Whisper or Scufris startup is visible through user-service or launcher diagnostics without restart loops.
- Module options, checks, package locks, and task evidence cover enabled and disabled composition.

## Verification

- Audit pinned package source and run its published checks where practical.
- Nix module evaluation checks.
- `nix flake check`.
- `nix build .#homeConfigurations.alex.activationPackage --no-link`.
- Fixture WAV transcription through the local endpoint.
- Live Ctrl+R microphone, popup toggle, session resume, and Piper playback after activation.
- `git diff --check`.

## Implementation evidence

- Added optional `programs.agents.pi.voiceStt` composition. It materializes the
  pinned npm extension, FFmpeg dependency, JSON configuration, and
  `PI_STT_CONFIG` only when enabled.
- Added `services.localVoice`. It owns pinned Whisper and Piper assets, the
  loopback user service, direct Kitty user service, exact class/instance plus
  i3 mark ownership, one idempotent toggle, and the dedicated Pi session
  directory. Runtime control does not depend on Pi's changing title.
- Kept popup defaults in its launcher environment only. Ordinary Scufris does
  not receive speech or Calm environment settings.
- Piper 1.4.2 accepts `--config` but does not pass that argument to its voice
  loader. The model and config are therefore materialized together as
  `model.onnx` and `model.onnx.json`. Its stdout mode also copies a temporary
  WAV before closing the writer and emits zero bytes. The pinned 1.4.2 package
  has a narrow close-before-copy patch. Composition checks cover normal-file
  and stdout synthesis.
- Whisper and popup units use `Restart=no`. The popup starts through one user
  unit from i3, and the hotkey starts that same unit only when its exact marked
  Kitty window does not exist.

## Package audit

- Scufris is locked to durable landed revision
  `57f0ca1111c0adebc744dfc340a8739c3a633a9a` (`Add Scufris spoken response mode`).
  The removed feature revision is not referenced.
- `pi-voice-stt` is locked at 0.6.0 with npm integrity
  `sha512-BdPdSA4ppixbDVLr4W26qvi57+G9J5vqv2ns7jHbDH8lV11pvfwc8LrIcgEXV4T7uksfKcfewUD+gVT8PtQZwQ==`.
- Audited npm gitHead `d040a0a3507b33915244f99066a2eeeb9d596675`.
- Published `npm run ci` passed: TypeScript check, 64 tests, and extension
  smoke test.
- `npm audit --omit=dev` reported zero vulnerabilities. The development-only
  graph reported one low and five high findings and is not in the Nix runtime
  closure.
- The extension uses `spawn` without a shell for FFmpeg, restricts plain HTTP
  to loopback hosts, omits authorization for loopback, and removes temporary
  recordings. AI cleanup is disabled in the deployed configuration.
- Pinned assets:
  - Whisper `large-v3-turbo-q5_0`: SHA-256
    `394221709cd5ad1f40c46e6031ca61bce88931e6e088c188294c6d5a55ffa7e2`.
  - Piper `en_US-lessac-medium` model: SHA-256
    `5efe09e69902187827af646e1a6e9d269dee769f9877d17b16b1b46eeaaf019f`.
  - Piper config: SHA-256
    `efe19c417bed055f2d69908248c6ba650fa135bc868b0e6abb3da181dab690a0`.

## Verification evidence

- `nix build .#checks.x86_64-linux.voice-stt .#checks.x86_64-linux.home-module --no-link`: passed.
- `nix build .#checks.x86_64-linux.local-voice .#checks.x86_64-linux.home-module --no-link`: passed. The ownership regression accepts an exact marked
  class/instance after Pi changes the title and rejects near-match class,
  instance, and mark fixtures.
- Root `nix flake check`: passed.
- Scufris revision `57f0ca1111c0adebc744dfc340a8739c3a633a9a` `nix flake check`: passed.
- `nix build .#homeConfigurations.alex.activationPackage --no-link`: passed.
- The landed Scufris `scufris-speak` helper with real patched Piper 1.4.2
  produced a valid non-empty RIFF/WAVE before the fake exact playback sink.
- That helper-generated fixture through the configured Vulkan Whisper server
  returned JSON text `Hello from the local voice test.` and `ss` showed only
  `127.0.0.1:10301`.
- Activation-only checks remain: live Ctrl+R microphone, `/stt doctor`,
  Super+S hide/show and resume, and audible PipeWire playback.
