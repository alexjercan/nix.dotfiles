{pkgs}: let
  extension = import ../mk-npm-extension.nix {
    inherit pkgs;
    npmRoot = builtins.toString ./.;
    packageName = "@plannotator/pi-extension";
  };
in {
  inherit extension;

  # One version for both halves: the locked npm version drives the CLI release.
  binary = pkgs.callPackage ./binary.nix {inherit (extension) version;};
}
