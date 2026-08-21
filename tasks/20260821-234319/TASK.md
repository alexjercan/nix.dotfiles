# Deploy local voice Scufris popup

- STATUS: OPEN
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
