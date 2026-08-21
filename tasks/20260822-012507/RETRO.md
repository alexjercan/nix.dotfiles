# Retro: Consume Scufris voice ownership

- TASK: 20260822-012507
- BRANCH: consume-scufris-voice

## What went well

- The landed Scufris interface exposed exactly the class, instance, service
  identity, launcher, and package outputs needed by the i3 consumer.
- Splitting voice STT from base Pi composition made custom-provider, managed
  Whisper, and disabled checks direct.
- Existing changed-title and near-match fixtures transferred cleanly to the
  focused i3-owned consumer.
- Activation-package checks covered both sides of each optional boundary
  without activating Home Manager.
- User transitional evidence established working Ctrl+R STT and Piper TTS
  before migration.

## What went wrong

- Running Alejandra across the agents directory initially reformatted one
  unrelated extension builder. The change was reverted before checks.
- One malformed jq test fragment entered the first local Whisper check edit.
  The focused build failed immediately, and the fragment was corrected.
- `nix fmt` is unavailable because this flake has no formatter output for the
  current system. The installed Alejandra executable formatted touched Nix
  files instead.

## What to improve next time

- Format only changed files to avoid unrelated diffs.
- Re-read generated shell fragments before the first build.
- Keep cross-project ownership tests at public option boundaries. Do not inspect
  or import private implementation files.

## Final ownership

- Agents own pi-voice-stt, FFmpeg capture, the default STT config, and optional
  loopback Vulkan Whisper.
- Scufris owns Piper, voice assets, speech environment, popup launcher,
  resumable session, and popup service definition.
- i3 owns popup startup, exact marked-window identity, geometry, and controls.
