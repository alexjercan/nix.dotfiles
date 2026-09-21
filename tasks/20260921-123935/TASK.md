# Research pi-ask-user integration

- STATUS: CLOSED
- PRIORITY: 0
- TAGS: 

Research edlsh/pi-ask-user, inspect local pi extension integration patterns, and report a proposed integration. Do not modify the integration.

## Findings

- Upstream npm package `pi-ask-user` 0.15.0 registers the sequential `ask_user` tool and bundles an `ask-user` skill.
- Current Pi 0.85.0 satisfies the upstream `>=0.74.0` peer requirement.
- Use the existing `mk-npm-extension.nix` pattern with exact npm and lockfile pinning.
- Add an auto-discovered `pi-ask-user` module with `enable` and `package` options.
- Preserve the bundled skill in the generated Pi package manifest; the current helper only forwards the extension.
- Keep full event payloads disabled by default because they expose answers to every extension.
- Validate with Home Manager activation package build and a short interactive smoke test.

## Implementation

Integration landed in the working tree. Status stays open for the parent.

### Files

- `home/modules/agents/pi/extensions/pi-ask-user/package.json`,
  `package-lock.json`: pin `pi-ask-user` 0.15.0.
- `home/modules/agents/pi/extensions/pi-ask-user/default.nix`: build through
  `mk-npm-extension.nix` with `skills = ["skills"]`.
- `home/modules/agents/pi/extensions/pi-ask-user/module.nix`: `enable` and
  `package` options plus the `pi.enable` assertion.
- `home/modules/agents/pi/extensions/mk-npm-extension.nix`: optional `skills`
  argument.
- `home/modules/agents/default.nix`: `pi-ask-user.enable = true;`.

### Design

- Pi resolves a `pi.extensions` directory entry through the dependency's own
  manifest but does not inherit its other resource kinds. A measurement with
  an extensions-only manifest registered `ask_user` and loaded no skill, so
  the wrapper manifest must name the skill root itself.
- `mk-npm-extension.nix` adds `pi.skills` only when `skills` is non-empty.
  The four existing extensions keep a byte-identical manifest.
- No settings option. Every preference is a `PI_ASK_USER_*` environment
  variable and the upstream defaults already match. `PI_ASK_USER_EMIT_FULL_EVENTS`
  stays unset so answers are not broadcast to other extensions.

### Checks

- `nix eval .#homeConfigurations.alex.config.programs.agents.pi.finalArgs`:
  the extension store path appears.
- Built `programs.agents.pi.extensions.pi-ask-user.package`. The generated
  manifest carries both `pi.extensions` and `pi.skills`.
- `pi-observational-memory` evaluates to the same store path with and without
  the `mk-npm-extension.nix` change.
- Built `.#homeConfigurations.alex.activationPackage`.
- Ran the wrapped `pi` against a loopback mock provider. The captured request
  lists the `ask_user` tool and the `ask-user` skill.
