# Deploy Scufris v2.1.5

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: scufris, deployment

## Goal

Pin the immutable Scufris v2.1.5 release, build the Home Manager activation,
switch the live desktop and service, and verify the owned user services.

## Context

The checkout still held the expected uncommitted v2.1.4 pin from its completed
switch. Advance that exact pin directly to v2.1.5; there are no unrelated local
changes.

## Verification

Completed on 2026-09-01:

- Updated `scufris` to annotated tag v2.1.5 and locked release commit `288cb19`.
- Alejandra formatting check passed.
- Built `.#homeConfigurations.alex.activationPackage`; the build compiled the
  2.1.5 desktop and service and passed their Rust tests.
- Activated generation
  `/nix/store/r20q9jcd6bhkrhm5sg866kaicc3852f7-home-manager-generation`.
- `scufris-service`, `scufris-desktop`, and `scufris-surface-gateway` are active
  and running. Their process executables resolve to 2.1.5 store paths.
- `scufris-ctl state` returned `idle`. The only fresh warning is the pre-existing
  GTK settings parser warning.
