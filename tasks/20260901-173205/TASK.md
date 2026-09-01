# Update Scufris to v2.1.3 and switch Home Manager

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: scufris

## Change

Pinned the `scufris` flake input to immutable release `v2.1.3` and refreshed
only that input in `flake.lock`.

## Verification

- `nix build .#homeConfigurations.alex.activationPackage --no-link`: passed.
- `home-manager switch --flake .#alex`: passed.
- Home Manager restarted `scufris-service`, `scufris-desktop`, and
  `scufris-surface-gateway`; all three units are active.
- Service, gateway, and desktop `ExecStart` paths are Scufris 2.1.3.
- The deployed packaged jobs helper resolves its dedicated
  `extensions/scufris/workflow/worker-report.ts` successfully.

