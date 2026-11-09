{pkgs}: let
  version = "0.1.0";
  source = pkgs.fetchFromGitHub {
    owner = "alexjercan";
    repo = "pi-btw";
    rev = "v${version}";
    hash = "sha256-W8Ym6dEYzFj0+lF7NgNeZk9qgE8sFCGi67GJNtFWjEI=";
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
