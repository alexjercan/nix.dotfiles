# Update Scufris input to v2.1.6

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: scufris, nix

## Goal

Pin the immutable Scufris v2.1.6 release without activation or deployment.
Preserve the gateway loopback client correction and all unrelated local changes.

## Constraints

- Update only the Scufris release input and its narrow lock closure.
- Run safe, non-activating focused checks.
- Do not build an activation package, switch, restart, deploy, stage, or commit.

## Change

- Updated the root Scufris input from annotated release tag v2.1.5 to v2.1.6.
- Narrowly updated only its lock node to release commit
  `7dca61ea9f0312fbfeb2d0c9b621c5c0a20f1810`.
- Preserved the existing unrelated llm-agents lock changes and the explicit
  loopback API client URL.

## Verification

- Upstream tag and published GitHub Release checks passed.
- Alejandra formatting passed.
- `nix flake check -L --no-build` passed without building outputs.
- Focused Home Manager evaluation selected Scufris 2.1.6 packages and retained
  `http://127.0.0.1:10300` in the shared, desktop, and gateway client settings.
- `git diff --check` passed.
- No package, generation, or activation output was built or activated.
