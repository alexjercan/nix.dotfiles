{
  config,
  lib,
  ...
}: let
  cfg = config.programs.agents;
in {
  options.programs.agents.pi = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether the agent workspace enables Pi.";
    };

    extensions = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.path lib.types.str);
      default = [];
      description = "Pi extensions to load.";
    };

    themes = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = "Pi themes to load.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.pi.coding-agent = {
      enable = cfg.pi.enable;
      extensions = cfg.pi.extensions;
      themes = cfg.pi.themes;
    };
  };
}
