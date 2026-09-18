# Investigate Pi theme loss after Nix store GC

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: bug

Investigate why Pi cannot load the gruber-darker theme after `sudo nix-store --gc` and why `home-manager switch --flake .#alex` repairs it. Do not fix it yet.

## Findings

- The installed Pi wrapper embeds the theme path under the evaluated flake source: `/nix/store/abb8dwnpac574a2lf09qllv2kc2h2cv3-source/home/modules/agents/pi/themes/gruber-darker.json`.
- The source store path is not a reference of the wrapper, the Home Manager generation, or the user environment. `nix-store --gc --print-dead` classifies it as dead.
- `builtins.toString ./.` in `home/modules/agents/pi/themes/module.nix` removes the Nix string context. The wrapper text retains the path characters, but its derivation does not declare the source as an input. Nix therefore does not register the source as a runtime reference.
- Store GC deletes the source while retaining the rooted wrapper. Pi then receives a dangling `--theme` path and reports the conflict and missing theme.
- A Home Manager switch evaluates the flake again and restores the same source store path, which makes the existing wrapper argument valid again.
- The current module comment states that the source subpath is anchored, but the closure data shows that this assumption is false.
- Existing checks only compare `finalArgs`. They do not verify that enabled resources are in the final package or generation closure.

## Proposed fix

Package each discovered theme file with `builtins.path` instead of converting the theme directory to a context-free string. Pass that path value through `finalArgs`. This gives the wrapper derivation a declared theme source input and makes the built wrapper reference the copied theme file. Add a closure test that checks the selected theme path is present in `finalPackage`'s closure.

A local proof with an equivalent `builtins.path` plus `writeShellScriptBin` produced a wrapper whose registered references include the isolated `pi-theme-gruber-darker.json` store path.

## Implementation

- Package each discovered theme as an isolated `builtins.path` store object.
- Keep that path's Nix context when it is passed to the generated Pi wrapper.
- Check that the configured theme is in the final wrapper closure.

## Validation

- `alejandra home/modules/agents/pi/themes/module.nix home/modules/agents/checks.nix`
- `nix build .#checks.x86_64-linux.home-module --no-link`
- `nix build .#homeConfigurations.alex.activationPackage --no-link`
- Confirmed the generated Pi wrapper directly references `/nix/store/si34rfn9rqwhx48snqlwc2771b2d5bra-pi-theme-gruber-darker.json`.
