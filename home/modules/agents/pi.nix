{
  config,
  lib,
  ...
}: let
  cfg = config.programs.agents;

  # Every module under pi-extensions/ declares `extensions.<name>.enable` and
  # `extensions.<name>.package`. Nothing here knows the individual names.
  enabledExtensions =
    lib.concatMap (ext: lib.optional ext.enable ext.package)
    (lib.attrValues cfg.pi.extensions);

  # themes/module.nix declares one `themes.<name>` per file in themes/.
  enabledThemes =
    lib.concatMap (theme: lib.optional theme.enable theme.source)
    (lib.attrValues cfg.pi.themes);
in {
  options.programs.agents.pi = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether the agent workspace enables Pi.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.pi.coding-agent = {
      enable = cfg.pi.enable;
      extensions = lib.mkIf cfg.pi.enable enabledExtensions;
      themes = lib.mkIf cfg.pi.enable enabledThemes;
    };
  };
}
