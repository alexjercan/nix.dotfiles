# Configure Pi Gemma provider

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: pi, nix

## Goal

Add the Gemma provider to the Nix-managed Pi agent config. Scout the existing
configuration first, then implement and validate with a worker. Include all
requested changes in one commit.

## Steps

- [x] A reusable option generates Pi's custom-provider catalogue declaratively.
- [x] The Gemma provider is declared from the repository's user configuration.
- [x] Changed Nix files are Alejandra-formatted.

## Correction: models.json, not config.json

The request named `~/.pi/agent/config.json`. Pi 0.85.0 does not read that name.
`libexec/pi/docs/models.md` states custom providers and models go in
`~/.pi/agent/models.json`, and `strings` over the pi binary finds `"models.json"`
and no `"config.json"`. The hand-written `~/.pi/agent/models.json` on this
machine already held exactly the requested provider block, which confirms the
path. Writing `config.json` would have produced a file pi ignores while leaving
the live file unmanaged, so the option targets `models.json`.

## Design

`settings.json` keeps its activation merge because pi writes to it itself (an
in-app theme switch lands there). Pi only reads `models.json`, so the new
`programs.agents.pi.models` option takes the simpler route: `pkgs.formats.json`
generates the file and `home.file` links it from the store. A hand-edited file
is then replaced, which is what a declarative provider catalogue wants.

`baseUrl` points at `http://localhost:10302/v1`, the `services.llama-cpp` port
already declared in the same file.

## Definition of Done

- [x] `nix build .#homeConfigurations.alex.activationPackage` succeeds
      (cmd: `nix build .#homeConfigurations.alex.activationPackage`).
- [x] The generated `home-files/.pi/agent/models.json` matches the requested
      provider shape and values exactly, and no `config.json` is produced
      (cmd: `diff <(jq -S . <generated>) <(jq -S . <expected>)`).

## Follow-up for activation

`~/.pi/agent/models.json` is still an unmanaged regular file and no
`home.backupFileExtension` is set, so the next `home-manager switch` refuses to
clobber it. Its content is byte-identical to the generated file, so deleting it
once before the switch loses nothing.
