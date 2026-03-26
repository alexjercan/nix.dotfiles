{
  inputs,
  lib,
  ...
}: let
  hostsDir = ../hosts;
  hostDirs = builtins.attrNames (lib.filterAttrs (name: type: type == "directory") (builtins.readDir hostsDir));
in {
  flake.nixosConfigurations = builtins.listToAttrs (
    map (hostName: {
      name = hostName;
      value = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          inherit inputs;
        };

        modules = [
          "${hostsDir}/${hostName}"
          {
            networking.hostName = hostName;
          }
        ];
      };
    })
    hostDirs
  );
}
