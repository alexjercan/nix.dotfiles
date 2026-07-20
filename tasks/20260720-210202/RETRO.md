# Retro: swap den scripts to the packaged today CLI

- TASK: 20260720-210202
- BRANCH: feature/today-cli-swap
- REVIEW ROUNDS: 1 (APPROVE)

## What went well

- Applied the repo's own ledger lessons directly: checked `nix flake check`
  green on master FIRST (`baseline-dod-proofs`), verified by nix-building only
  the `today` package rather than a full home rebuild (`build-just-the-package`),
  and landed with `sprout land` from the main checkout (`land-from-the-main-checkout`).
- The overlay consumption was frictionless because the today repo had already
  exported `flake.overlays.default` in its own finalize task - the two halves of
  the swap (produce the overlay, consume it) were designed to meet.
- Consolidating the two skills into one matched the new reality (one binary does
  read + create + mutate), and deleting ~1500 lines of bash + a whole skill left
  the surface smaller and truer.

## What went wrong

- Nothing broke. The one risk was the rewritten skill drifting from the real
  CLI: flag names, `note list` scoping (day vs the old cross-day), and the
  `show --json` keys all changed from the old `daily`, so editing the old doc
  from memory would have shipped wrong examples. Mitigated by smoke-testing the
  packaged binary end to end before review, and the reviewer re-ran every
  documented command against the binary.

## Decisions recorded

- Retired the `daily` skill entirely (folded into `today`) rather than keeping a
  pointer stub - one binary, one skill; the `today` description carries the
  habits/tasks/macros/weight/notes trigger words the old `daily` description had.
- `daily -w` PNG weight plot is not ported (`today weight` gives a text trend);
  left dropped, reopen if wanted.
- Manual `home-manager switch` (activate + confirm `which today`/`which daily`)
  is the user's acceptance step, batched.

## What to improve next time

- When a doc surface (skill/README) documents a CLI, regenerate its examples by
  RUNNING the new binary, never by editing the predecessor's doc - a replaced
  tool changes flag names, output keys and scoping that a memory-edit silently
  keeps wrong.

## Action items

- [x] LESSONS.md: `doc-a-cli-from-its-real-output`.
- [ ] User: `home-manager switch`, then confirm `which today` -> Nix store and
      `which daily` is gone (manual acceptance).
