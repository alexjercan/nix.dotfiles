# Remove pointless tests

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: tests

Remove checks that only freeze dependency versions. Keep behavioral integration
coverage for the reusable agent module and the Sprout script.

## Steps

- [x] Inventory repository tests and flake checks.
- [x] Remove dependency version pin checks.
- [x] Run the remaining flake checks.

## Definition of Done

- No check asserts a fixed Scufris, Quick Review, or voice-stt version.
- Reusable module and script behavior checks remain.
- `nix flake check` passes.

## Close-out

Removed the obsolete Scufris v0.2.0 revision check and its input plumbing.
Removed fixed-version assertions for Quick Review and voice-stt. Also removed
Quick Review output-hygiene checks and tautological Plannotator version checks.

Kept the checks for `home/modules/agents/` because it is a large reusable Home
Manager module with packaged extensions and cross-module Scufris/i3 behavior.
Kept `sprout-test.sh` because Sprout is a stateful Git and tmux script. These are
the two exceptions allowed by this task's scope.

Evidence: `nix flake check` passed all checks.

A follow-up sweep found no other test files or fixed-version checks. The
remaining `mk-npm-extension.nix` assertions validate package metadata and lock
file consistency. The voice-stt module assertions reject invalid user
configuration. They are runtime configuration guards, not tests.
