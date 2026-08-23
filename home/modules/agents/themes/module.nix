{sourceRoot ? ../.}: {lib, ...}: let
  themeRoot = sourceRoot + "/themes";
  entries = builtins.readDir themeRoot;

  # Key every option by the name inside the file: that is the value Pi expects
  # in `programs.pi.coding-agent.settings.theme`.
  themes = builtins.listToAttrs (map (file: {
      name = (lib.importJSON (themeRoot + "/${file}")).name;
      value = file;
    })
    (builtins.filter (lib.hasSuffix ".json") (builtins.attrNames entries)));
in {
  options.programs.agents.pi.themes =
    builtins.mapAttrs (name: file: {
      enable = lib.mkEnableOption "the ${name} Pi theme";

      source = lib.mkOption {
        type = lib.types.path;
        default = themeRoot + "/${file}";
        defaultText = lib.literalExpression "themes/${file}";
        description = "Theme JSON loaded for ${name}.";
      };
    })
    themes;
}
