{
  pkgs,
  sourceRoot ? ../.,
}: let
  # Every subdirectory is one self-contained extension: `default.nix` builds its
  # packages and `module.nix` declares its Home Manager options.
  entries = builtins.readDir (sourceRoot + "/pi-extensions");
  names = builtins.filter (name: entries.${name} == "directory") (builtins.attrNames entries);
in
  builtins.listToAttrs (map (name: {
      inherit name;
      value = import (./. + "/${name}") {inherit pkgs sourceRoot;};
    })
    names)
