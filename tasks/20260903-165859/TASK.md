# Migrate llama.cpp to ai-tools-api v0.2.0

- STATUS: OPEN
- PRIORITY: 100
- TAGS: nix,llm,service

## Goal

Use `ai-tools-api` v0.2.0 as the sole llama.cpp service owner. Remove the old
NixOS llama.cpp router and mutable model cache cleanup. Expose the combined API
on TCP port 10300 to loopback, Tailscale, and the local LAN.

## Decisions

- Keep both hash-pinned Q8 model aliases owned by `ai-tools-api`.
- Override the Home Manager llama.cpp package with CUDA support on this host.
- Bind the API to `0.0.0.0`; restrict reachability with the NixOS firewall.
- Permit port 10300 on `tailscale0` and from `192.168.0.0/24` only.
- Remove port 11433 rules, `services.llama-cpp`, and its cache cleanup timer.
- Keep the developer `llama-cpp` package. It is not a service owner.
- Preserve pre-existing unrelated `flake.lock` updates.

## Verification

- `alejandra --check` passed for all changed Nix files.
- `git diff --check` passed.
- `nix flake check -L` passed all 17 checks and evaluated the NixOS host.
- `nix build .#homeConfigurations.alex.activationPackage -L` passed.
- `nix build .#nixosConfigurations.nixos.config.system.build.toplevel -L`
  passed.
- Evaluated Home Manager with host `0.0.0.0`, llama.cpp enabled, and the
  `ai-tools-api`, `ai-tools-api-llama`, and `ai-tools-api-whisper` units.
- Evaluated NixOS without `llama-cpp.service` and with ports 22 and 10300
  allowed on `tailscale0`.
- Applied the Home Manager generation. The three API units are active and
  sockets listen on `0.0.0.0:10300` and `127.0.0.1:10302`.
- NixOS activation is pending because `sudo` needs an interactive terminal.
  Until activation, the old `llama-cpp.service`, cache timer, port 11433, and
  old firewall rules remain active.
