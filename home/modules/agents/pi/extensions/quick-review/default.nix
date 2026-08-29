{pkgs}: let
  version = "0.2.0";
  source = pkgs.fetchFromGitHub {
    owner = "alexjercan";
    repo = "quick-review";
    rev = "v${version}";
    hash = "sha256-dsbcwZuH8w69CQ+ypDbJ2FB5GgFolApRKVYNjgGk1Lc=";
  };
  extension =
    pkgs.runCommand "quick-review-${version}" {
      passthru = {inherit version;};
    } ''
      mkdir -p "$out"
      cp -R ${source}/extensions "$out/extensions"
      cp -R ${source}/commands "$out/commands"
      cp -R ${source}/docs "$out/docs"
      cp -R ${source}/.claude-plugin "$out/.claude-plugin"
      cp ${source}/.mcp.json "$out/.mcp.json"
      cp ${source}/package.json "$out/package.json"
      cp ${source}/README.md "$out/README.md"
      cp ${source}/LICENSE "$out/LICENSE"
    '';
in {
  inherit extension;
}
