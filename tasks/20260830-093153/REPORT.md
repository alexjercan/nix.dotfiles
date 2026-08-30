# Shared speech API integration review

## Decision

Use `ai-tools-api` as the one speech inference owner on this machine.

- Point `pi-voice-stt` at `http://127.0.0.1:10300/v1/audio/transcriptions`.
- Stop the Pi Home Manager integration from creating `whisper-server`.
- Point Scufris at the same public transcription route after making its request OpenAI-compatible.
- Let only `services.ai-tools-api` own the Vulkan Whisper process, model, port 10301, bounds, and restart policy.

This is feasible. Pi needs configuration only. Scufris needs a small client contract change before deployment.

## Current architecture

There are three separate ownership layers:

1. `nix.dotfiles/home/modules/agents/pi/extensions/voice-stt/module.nix` can create `whisper-server.service` on `127.0.0.1:10301/inference`. The canonical configuration enables it in `home/modules/agents/default.nix`.
2. `scufris2` can create its own bundled `scufris-whisper.service` on port 10302, but the dotfiles already disable that path by configuring the shared port 10301 endpoint in `home/modules/scufris/default.nix`.
3. `ai-tools-api` creates `ai-tools-api-whisper.service` on `127.0.0.1:10301/private-inference` and exposes the bounded public API on `127.0.0.1:10300`.

The live machine currently has only `whisper-server.service` enabled and active. It listens on loopback port 10301. The two `ai-tools-api` units are not installed.

## Compatibility

### Pi voice STT: compatible now

`pi-voice-stt` 0.6.0 already has the required generic OpenAI-compatible provider. Its request includes:

- `file` as a WAV upload
- `model=whisper-1`
- optional normalized `language`
- `response_format=json`

It expects a JSON object with `text`. This exactly matches `ai-tools-api` release 0.1 at `POST /v1/audio/transcriptions`.

The required generated provider is conceptually:

```json
{
  "type": "openai-compatible",
  "endpoint": "http://127.0.0.1:10300/v1/audio/transcriptions",
  "model": "whisper-1",
  "language": "auto",
  "apiKeyEnv": ""
}
```

No Pi extension fork or new Pi extension is needed. Microphone capture remains in `pi-voice-stt`; only inference ownership moves.

### Scufris desktop: almost compatible

Scufris already has a narrow HTTP transcriber and accepts a configured endpoint. Its response handling already accepts the API's `{"text":"..."}` result.

Its multipart request is not currently compatible:

- It sends `file`.
- It sends `response_format=json`.
- It sends the whisper.cpp-specific `temperature=0.0` field.
- It does not send the required `model=whisper-1` field.

Therefore, changing only `SCUFRIS_STT_ENDPOINT` would fail validation. Scufris should add `model=whisper-1`, remove the unused `temperature` field, and describe the endpoint as OpenAI-compatible rather than whisper-server-compatible. Its endpoint then becomes `http://127.0.0.1:10300/v1/audio/transcriptions`.

This should remain a small Scufris-owned change in `surfaces/desktop/src/stt.rs`, with its request tests and Home Manager documentation updated. The API contract should not be weakened to accommodate the old client.

## Other useful consumers

### Scufris speech synthesis

`ai-tools-api` also exposes `POST /v1/audio/speech` using the same Piper 1.4.2 voice and pinned `en_US-lessac-medium` assets that Scufris currently packages in `nix/speak.nix`.

This is a real consolidation opportunity, but it is separate from STT:

- Current Scufris calls a local executable hook that reads text from stdin, runs Piper, and plays through PipeWire.
- The API returns WAV and never plays it.
- Reuse would need a small trusted Scufris speech helper that posts the text, bounds the WAV response, and plays it locally.

Recommendation: defer this until after STT migration. It removes duplicate Piper package/model ownership, but it changes more than an endpoint and needs explicit failure and audio playback tests.

### Remaining repositories

A source scan under `~/personal` found no other concrete STT or TTS runtime consumers outside `nix.dotfiles`, `scufris2`, and `ai-tools-api`. The broad matches in Nova repositories were ordinary prose or game terms, not speech inference integrations.

## Recommended implementation plan

### 1. Make Scufris compatible and release it

In `~/personal/scufris2`:

1. Change the desktop multipart body to send `model=whisper-1`, `file`, and `response_format=json`.
2. Remove `temperature=0.0`.
3. Rename contract prose from whisper-server-compatible to OpenAI-compatible transcription.
4. Update endpoint examples and checks to use the API route where they describe the canonical shared deployment. Keep bundled whisper-server support if standalone Scufris still needs it; its client can use the OpenAI-style fields with whisper.cpp.
5. Add a focused integration test against a fake server that asserts fields and response parsing.
6. Run the focused Rust tests and Scufris Nix checks.
7. Release and pin a new Scufris tag before changing the canonical dotfiles input.

Scufris currently has unrelated uncommitted staging work. Keep this migration separate from those changes.

### 2. Publish or pin `ai-tools-api`

In `~/personal/ai-tools-api`:

1. Decide the immutable source for dotfiles. The repository currently has no release tag; HEAD is `217348f`.
2. Prefer a release tag for the existing 0.1 API contract, or pin the exact revision if release work is not wanted.
3. No API source change is required for Pi STT.
4. Verify its existing API, package, and Home Manager checks before consumption.

### 3. Deploy the API and redirect clients atomically

In `~/personal/nix.dotfiles`:

1. Add the immutable `ai-tools-api` flake input, following the root `nixpkgs` and Home Manager inputs where supported.
2. Import `inputs.ai-tools-api.homeModules.default` and enable `services.ai-tools-api`.
3. Configure `pi-voice-stt` with the public API endpoint and disable its `localWhisper` service.
4. Configure Scufris transcription with the same public API endpoint.
5. Update the pinned Scufris release.
6. Add Home Manager checks that prove:
   - `ai-tools-api.service` and `ai-tools-api-whisper.service` exist;
   - the old `whisper-server.service` and `scufris-whisper.service` do not exist;
   - Pi's generated `stt.json` names port 10300 and `/v1/audio/transcriptions`;
   - Scufris receives the same endpoint;
   - only the API's private Whisper unit owns port 10301.
7. Consider deleting the agent module's `localWhisper` option, model fetch, and service after the canonical migration. Keeping generic provider settings is useful; keeping two alternative Whisper owners is not. This cleanup can be in the same task if all exported checks move together, or in a direct follow-up.

The deployment switch must be atomic because both the old Pi-owned server and the API-owned private server use port 10301.

### 4. Verify live behavior

1. Build the focused Home Manager checks and activation package.
2. Activate once after review.
3. Confirm only `ai-tools-api-whisper` listens on `127.0.0.1:10301` and only the API listens on the configured 10300 address.
4. Call the public transcription route with a fixture WAV.
5. Run Pi `/stt doctor` and one live Ctrl+R dictation.
6. Run one live Scufris dictation.
7. Confirm API overload, timeout, and unavailable errors become short client-visible failures without transcript loss.
8. Confirm no speech text or audio appears in logs.

## Risks and notes

- The API defaults to two concurrent STT requests, but whisper.cpp serializes inference internally. The bound is safe but does not guarantee parallel GPU work.
- Pi uses a 60-second default provider timeout unless configured otherwise, while the API permits 120 seconds. Interactive recordings should fit, but align these values deliberately.
- The API has no authentication. Loopback deployment is appropriate. Its docs permit a Tailscale bind, but `pi-voice-stt` rejects plain HTTP to non-loopback hosts; a remote deployment would need HTTPS and a separate authentication decision.
- The API currently couples STT and TTS service availability to one unit and requires its owned Whisper unit. That is acceptable for this host, but it is not yet a generic external-Whisper Home Manager deployment interface.
- Do not point clients at `/private-inference`. That route is an implementation detail with none of the API's public validation, concurrency, error normalization, or stable contract.
