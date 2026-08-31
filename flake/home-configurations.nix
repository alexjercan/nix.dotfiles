{
  inputs,
  lib,
  ...
}: let
  # Subpath of the flake source (inputs.self), not a `../home` path literal:
  # the literal coerces to a floating `<hash>-home` store root that GC reaps
  # out from under the flake eval cache. See nixos-configurations.nix.
  homeDir = "${inputs.self}/home";
  userDirs = builtins.attrNames (lib.filterAttrs
    (name: type: type == "directory" && name != "modules")
    (builtins.readDir homeDir));
in {
  flake.homeConfigurations = builtins.listToAttrs (
    map (userName: {
      name = userName;
      value = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          # pkgs is passed to home-manager explicitly, so the in-module
          # `nixpkgs.config.allowUnfree` is ignored - set it here.
          config.allowUnfree = true;
          overlays = [
            inputs.tatr.overlays.default
            inputs.llm-agents.overlays.shared-nixpkgs
          ];
        };

        extraSpecialArgs = {
          inherit inputs;
          nixvim = inputs.nixvim;
        };

        # NOTE: no `sops-nix.homeManagerModules.sops` here. Secrets for this
        # machine are decrypted at the SYSTEM level (hosts/nixos/default.nix)
        # and consumed by the home config as a plain /run path, because the same
        # secret must also reach a root unit that starts before any user session
        # exists - see tasks/20260730-190929/DECISION.md. A non-NixOS host would
        # add the module back and render its own env file; keeping an unused
        # module here would only suggest home-manager decrypts something.
        modules = [
          "${homeDir}/${userName}"
          inputs.nix-index-database.homeModules.default
        ];
      };
    })
    userDirs
  );
}
