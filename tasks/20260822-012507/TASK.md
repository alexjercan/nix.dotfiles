# Consume Scufris voice ownership

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: voice, nix, architecture

## Goal

Replace the temporary `services.localVoice` composition with the landed Scufris voice interface. Keep global STT and Whisper in the agent integration. Keep only i3 presentation and control in `nix.dotfiles`.

## Dependency

Pin and consume landed Scufris revision:

```text
f92c72c Add optional Scufris voice runtime
```

Do not import `inputs.scufris/nix/launcher.nix` directly. Use the public Home Manager interface.

## Accepted configuration

The host configuration becomes conceptually:

```nix
programs.agents.pi.voiceStt = {
  enable = true;
  localWhisper.enable = true;
};

programs.scufris = {
  enable = true;
  piPackage = config.programs.pi.coding-agent.finalPackage;
  voice = {
    enable = true;
    popup.enable = true;
  };
};

xsession.windowManager.i3.scufrisPopup.enable = true;
```

Exact option nesting may follow existing module conventions, but ownership must remain clear.

## Global STT ownership

- Keep pinned `pi-voice-stt` 0.6.0 and FFmpeg capture in the agent integration.
- Move the loopback Whisper model, service, and generated provider configuration under a focused `programs.agents.pi.voiceStt.localWhisper` module or equivalent narrow agent-owned file.
- Preserve `whisper-cpp-vulkan`, pinned `large-v3-turbo-q5_0`, language auto, and loopback-only `127.0.0.1:10301/inference`.
- Write generated STT configuration to the extension default `~/.pi/agent/stt.json`.
- Remove `PI_STT_CONFIG` session and popup wiring.
- Prevent ambiguous simultaneous custom provider and managed local Whisper settings. Prefer a direct assertion over merging conflicting providers.
- Normal Pi and local Scufris development must discover STT without launcher environment.

## Scufris ownership

- Configure the public `programs.scufris.voice` and popup options.
- Let the Scufris module provide Piper, pinned voice assets, speech composition, trusted environment, popup launcher, session, and `scufris-popup.service`.
- Remove the private popup package import, Piper model/config fetches, Piper override/overlay, popup launcher, Kitty launcher, and popup service from `nix.dotfiles`.
- Remove `services.localVoice` completely. Do not preserve aliases or compatibility options.

## i3 consumer ownership

- Keep Super+S, Print, and Shift+Print behavior.
- Keep exact class and instance matching, i3 ownership mark, centered 1000x720 floating geometry, startup policy, stable owner query, and idempotent toggle in `nix.dotfiles`.
- Read popup class, instance, and service identity from public `programs.scufris.voice.popup` options.
- Keep title out of runtime ownership.
- Put substantial Scufris popup integration in a focused i3-owned module rather than restoring a generic local voice module or bloating the base i3 file.
- The i3 consumer starts and toggles the service. Scufris defines the service but does not install or start it.

## Definition of done

- `services.localVoice` and its module are gone.
- No Piper package, model, config, patch, overlay, speech environment, popup launcher, or popup systemd unit remains owned by `nix.dotfiles`.
- No direct Scufris launcher import remains.
- Global Pi STT and loopback Whisper remain independently optional and tested.
- `~/.pi/agent/stt.json` works without `PI_STT_CONFIG`.
- i3 consumes only public Scufris popup metadata and service identity.
- Enabled and disabled module compositions evaluate.
- Existing non-voice agent, Pi, i3, and Scufris behavior remains correct.
- Task evidence and retro explain the final ownership boundaries.

## Verification

- Focused enabled and disabled Home Manager evaluations.
- Voice-STT package and local Whisper checks.
- i3 changed-title and near-match ownership checks.
- Exact Scufris landed revision assertion.
- `nix flake check`.
- `nix build .#homeConfigurations.alex.activationPackage --no-link`.
- `git diff --check`.
- No live activation before structured review approval.

## Pre-migration transitional evidence

- User reported that current Scufris master worked through `nix develop` with
  `PI_STT_CONFIG=$HOME/.config/pi-voice-stt/config.json npm run dev:voice`.
- The transitional run provided both Ctrl+R recording/STT and Piper TTS.
- Post-activation acceptance remains the same behavior through the extension
  default `~/.pi/agent/stt.json`, with no `PI_STT_CONFIG`.

## Implementation evidence

- Pinned exact landed Scufris revision
  `f92c72c0a6525b40e18165a72d828c41ede91907` and consumed only its public Home
  Manager module.
- Split Pi voice STT into a focused agent-owned module. It keeps the pinned
  0.6.0 extension and FFmpeg, writes `~/.pi/agent/stt.json`, and optionally owns
  the pinned Vulkan Whisper model, loopback service, and generated provider.
- Managed local Whisper rejects any custom `settings.provider`. Custom provider
  STT remains valid when managed Whisper is disabled.
- Configured Scufris voice and popup through `programs.scufris.voice`. Scufris
  now owns Piper, voice assets, trusted speech environment, popup launcher,
  session policy, and the uninstalled popup service.
- Deleted `services.localVoice`, its exported module, the Piper overlay and
  patch, direct launcher import, model fetches, launchers, and popup service.
- Added a focused i3 popup consumer. It reads Scufris class, instance, and
  service identity; owns the exact mark, owner query, idempotent toggle, login
  start, Super+S, and centered 1000x720 scratchpad policy; and never uses title
  for ownership.
- Enabled, disabled, invalid ownership, custom endpoint, managed endpoint,
  package pin, generated config, exact revision, changed-title, near-match, and
  activation-package compositions are checked.

## Verification evidence

- Focused voice STT, local Whisper, Scufris popup, exact revision, and Home
  module builds passed.
- Implementation revision: `7456ce7`.
- `sprout sync consume-scufris-voice` passed after the implementation commit;
  the branch was already up to date.
- Post-sync `nix flake check` passed, including all focused checks.
- Post-sync
  `nix build .#homeConfigurations.alex.activationPackage --no-link` passed.
- `git diff --check` passed.
- Repository scans found no `services.localVoice`, local voice module, direct
  Scufris launcher import, or assigned `PI_STT_CONFIG`.
- No Home Manager activation was run.

## Post-approval activation

- Apply Home Manager.
- Verify Whisper is active and loopback-only on the Vulkan GPU.
- Verify normal Pi and `npm run dev:voice` discover STT without `PI_STT_CONFIG`.
- Verify the Scufris popup service, exact i3 mark, Super+S toggle, microphone capture, Piper playback, and resumable session.
