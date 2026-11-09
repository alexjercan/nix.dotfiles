{pkgs}: let
  version = "0.1.0";
  source = pkgs.fetchFromGitHub {
    owner = "alexjercan";
    repo = "pi-btw";
    rev = "7834f16fe47cc2f00d7cc8142473d3b39f5e2edd";
    hash = "sha256-E+zKFgV11BbfXiVZ7HqXO+JcnEYhez68vmX/7aDKTiU=";
  };
  # Pi supplies the peer dependencies; this package has no runtime dependencies.
  extension =
    pkgs.runCommand "pi-btw-${version}" {
      passthru = {inherit source version;};
    } ''
      mkdir -p "$out"
      cp -R ${source}/extensions "$out/extensions"
      cp -R ${source}/examples "$out/examples"
      cp ${source}/package.json "$out/package.json"
      cp ${source}/README.md "$out/README.md"
    '';
in {
  inherit extension source;
}
