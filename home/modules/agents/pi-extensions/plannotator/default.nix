{
  pkgs,
  sourceRoot ? ../../.,
}: let
  extension = import ../mk-pi-npm-extension.nix {
    inherit pkgs;
    npmRoot = sourceRoot + "/pi-extensions/plannotator";
    packageName = "@plannotator/pi-extension";
  };
in {
  inherit extension;

  # One version for both halves: the locked npm version drives the CLI release.
  binary = pkgs.callPackage ./binary.nix {inherit (extension) version;};
}
