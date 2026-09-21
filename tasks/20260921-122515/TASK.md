# Add Pi observational memory

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: pi, nix

## Goal

Package and enable pi-observational-memory v3.1.4 as a reproducible Pi
extension. Configure its worker model as the built-in OpenAI gpt-5.6-luna model
with medium thinking. Validate the Home Manager activation build and commit the
complete follow-up as one commit.

## Steps

- [x] A pinned pi-observational-memory 3.1.4 extension package builds from the
      existing `mk-npm-extension.nix` pattern.
- [x] The extension is enabled from the repository's user configuration.
- [x] The memory workers run on the built-in `openai` / `gpt-5.6-luna` model
      with `thinking = "medium"`.
- [x] Changed Nix files are Alejandra-formatted.

## Design

`home/modules/agents/pi/extensions/pi-observational-memory/` follows the
`voice-stt` and `plannotator` shape: a private `package.json` pinning the exact
npm version, its `package-lock.json`, and a `default.nix` that calls
`mk-npm-extension.nix`. The package has zero direct dependencies and declares
`pi.extensions = ["./src/index.ts"]`, so the generated wrapper manifest pointing
at `./node_modules/pi-observational-memory` is enough; `--legacy-peer-deps`
already covers its four `@earendil-works/*` peer dependencies, which pi supplies
at runtime.

`module.nix` only declares `enable` and `package`. The extension reads its
configuration from the `observational-memory` key of pi's own `settings.json`
(`src/config.ts`, `SETTINGS_KEY`), which `programs.agents.pi.settings` already
manages, so no second option tree and no extra file are needed.

## Correction: no separate config file, no models.json entry

`src/config.ts` reads `~/.pi/agent/settings.json` and project `.pi/settings.json`
and takes the nested `observational-memory` object. It reads no file of its own,
so the configuration is declared inline in `programs.agents.pi.settings`.

`normalizeModel` accepts `{ provider, id, thinking }` with `thinking` from
`off|minimal|low|medium|high|xhigh|max`, so the model value is nested rather
than flattened. `gpt-5.6-luna` is a built-in model of pi 0.85.0's `openai`
provider - the id is present in the pi binary and `libexec/pi/docs/models.md`
documents it alongside `gpt-5.6` and `gpt-5.6-terra` - so `models.json` stays
unchanged.

## Definition of Done

- [x] The extension package builds
      (cmd: `nix build .#homeConfigurations.alex.config.programs.agents.pi.extensions.pi-observational-memory.package`).
- [x] `programs.agents.pi.finalArgs` carries the new `--extension` path and
      `programs.agents.pi.settings` carries the nested model
      (cmd: `nix eval --json .#homeConfigurations.alex.config.programs.agents.pi.settings`).
- [x] `nix build .#homeConfigurations.alex.activationPackage` succeeds
      (cmd: `nix build .#homeConfigurations.alex.activationPackage`).
