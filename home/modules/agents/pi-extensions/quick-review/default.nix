{
  pkgs,
  sourceRoot ? ../../.,
}: let
  version = "0.1.0";
  source = pkgs.fetchFromGitHub {
    owner = "alexjercan";
    repo = "quick-review";
    rev = "v${version}";
    hash = "sha256-WuYYoPOvGodpauqYeb5bKK2LPrhlGopwhUrOlTAa5iw=";
  };
  extension =
    pkgs.runCommand "quick-review-${version}" {
      passthru = {inherit version;};
    } ''
      mkdir -p "$out"
      cp -R ${source}/extensions "$out/extensions"
      cp -R ${source}/docs "$out/docs"
      cp ${source}/package.json "$out/package.json"
      cp ${source}/README.md "$out/README.md"
      cp ${source}/LICENSE "$out/LICENSE"
    '';
in {
  inherit extension;
}
