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
          overlays = [
            inputs.tatr.overlays.default
            inputs.today.overlays.default
            inputs.macros-nvim.overlays.default
          ];
        };

        extraSpecialArgs = {
          inherit inputs;
          nixvim = inputs.nixvim;
        };

        modules = [
          "${homeDir}/${userName}"
          inputs.nix-index-database.homeModules.default
        ];
      };
    })
    userDirs
  );
}
