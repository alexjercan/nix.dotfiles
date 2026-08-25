{pkgs}: let
  version = "0.1.1";
  source = pkgs.fetchFromGitHub {
    owner = "alexjercan";
    repo = "quick-review";
    rev = "v${version}";
    hash = "sha256-eN585HEqYQr5mh6I7Uh8kjVFVxJNtkR4HV7ZT7lQjmI=";
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
