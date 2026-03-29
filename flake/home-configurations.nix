{
  inputs,
  lib,
  ...
}: let
  homeDir = ../home;
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
          overlays = [inputs.tatr.overlays.default];
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
