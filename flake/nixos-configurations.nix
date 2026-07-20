{
  inputs,
  lib,
  ...
}: let
  # Reference hosts as a subpath of the flake source (inputs.self) rather than
  # a `../hosts` path literal. Coercing the literal to a string copies the
  # directory into the store as its own floating `<hash>-hosts` root, which is
  # not a GC root: nix-collect-garbage reaps it while the flake eval cache
  # still points at it, so `nix flake check` later fails with
  # "path '...-hosts' is not valid". A subpath of inputs.self is addressed
  # within the single flake source root, which Nix re-copies from the tracked
  # git tree on every evaluation, so GC can never orphan it in the eval cache.
  hostsDir = "${inputs.self}/hosts";
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
