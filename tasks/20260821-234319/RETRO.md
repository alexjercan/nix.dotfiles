# Retro: Deploy local voice Scufris popup

- TASK: 20260821-234319
- BRANCH: local-voice-popup

## What went well

- The existing npm extension builder made the runtime lock small and auditable.
- Real Piper and Whisper fixtures found integration defects that fake process
  tests did not find.
- Enabled and disabled Home Manager evaluations kept the new boundary optional.

## What went wrong

- Piper 1.4.2 ignores its config argument during loading and requires the config
  beside the model.
- Piper 1.4.2 stdout mode copied its temporary WAV before closing the writer and
  emitted zero bytes. The first helper checks did not model this upstream bug.
- The first Scufris lock used a temporary feature ref instead of the durable
  landed revision.
- Popup ownership first included Kitty's initial title. Pi changes that title
  during interactive startup, which made the idempotent toggle miss its window.

## What to improve next time

- Run one real dependency fixture before accepting fake process tests.
- Pin cross-project inputs only after their durable revision exists.
- Test both file and stream interfaces when a helper composes two CLI tools.
- Use stable class, instance, and window-manager marks for ownership. Treat
  application titles as display data.
