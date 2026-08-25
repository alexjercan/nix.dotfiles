{lib, ...}: let
  # `toString` of a path literal, never the bare path: a bare path coerced into
  # a derivation copies this directory to its own floating `<hash>-themes` store
  # root that GC reaps out from under the flake eval cache. `toString` yields
  # the anchored subpath of the flake source instead.
  themeRoot = builtins.toString ./.;
  entries = builtins.readDir themeRoot;

  # Key every option by the name inside the file: that is the value Pi expects
  # in `programs.agents.pi.settings.theme`.
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
        defaultText = lib.literalExpression "pi/themes/${file}";
        description = "Theme JSON loaded for ${name}.";
      };
    })
    themes;
}
