# Deploy Scufris v2.1.0

- STATUS: OPEN
- PRIORITY: 100
- TAGS: scufris,deployment

## Goal

Pin immutable Scufris `v2.1.0` and activate it. The release adds the morning
briefing and changes how the service handles an answer nobody asked for.

## Acceptance

- The Scufris input names tag `v2.1.0` and resolves to release commit
  `9e2f1fa83523eeeaa7a802062d27305b404c2c03`.
- `nix flake check -L` and the Home Manager activation package build pass.
- Service, desktop, and gateway units are active after activation, and the
  three Scufris executables report version 2.1.0.
- A morning briefing collects from the declaring projects and reaches the
  conversation window rather than being refused.

## Verification

Activated on 2026-08-31:

- `flake.nix` names `github:alexjercan/scufris2/v2.1.0` and `flake.lock` holds
  rev `9e2f1fa83523eeeaa7a802062d27305b404c2c03`.
- `nix build .#homeConfigurations.alex.activationPackage --no-link` and
  `nix flake check -L` both passed, and `alejandra --check .` is clean.
- `home-manager switch --flake .#alex` restarted the service, desktop, and
  gateway units. All three report active.
- The upstream release is green: the `check`, iOS, and release workflows all
  succeeded, and the tag matched the package version.
- The packaged helper layout is right. `share/scufris/tools/briefing/cli.py`
  exists beside the extensions, and the restarted agent spawned it from that
  path. The working-tree-only path bug is gone.
- The morning ran for real. It collected `personal/scufris2`,
  `personal/the-den`, `personal/nova-protocol`, and `personal/seedzero`, and
  the run reached `delivered` with its prose, manifest, and page written. The
  service logged no refusal.
- Two projects answered with something the envelope could not take:
  nova-protocol sent unterminated JSON, and seedzero sent a headline over 200
  characters. Both were recorded as failed and named, which is the designed
  behaviour, but both guidance files need tightening.
- Startup found a defect. pi runs the `session_start` listeners one after
  another, and the briefing extension awaited the whole collection, so the
  agent reached `agent.sock` only when the sources had finished: started
  17:26:14, connected 17:28:27. Surfaces could not reach it in between.
  Fixed in scufris2 by commit `ec38afb`, which is not in v2.1.0.
- The sources cannot run commands. Both `claude` sources reported that their
  shell calls were denied: nova-protocol could not reach `gh`, and seedzero
  could not reach `python3`, so neither refreshed anything. `--permission-mode
  dontAsk` is already set and `Bash` is allowed, so the denial is the sandbox
  and not the permission mode. A source that needs a command currently answers
  from files alone.

