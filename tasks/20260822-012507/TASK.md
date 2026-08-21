# Consume Scufris voice ownership

- STATUS: IN_PROGRESS
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

## Post-approval activation

- Apply Home Manager.
- Verify Whisper is active and loopback-only on the Vulkan GPU.
- Verify normal Pi and `npm run dev:voice` discover STT without `PI_STT_CONFIG`.
- Verify the Scufris popup service, exact i3 mark, Super+S toggle, microphone capture, Piper playback, and resumable session.
