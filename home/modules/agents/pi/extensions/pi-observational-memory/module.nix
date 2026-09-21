{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.agents;
  extCfg = cfg.pi.extensions.pi-observational-memory;
  self = import ./. {inherit pkgs;};
  json = pkgs.formats.json {};
in {
  options.programs.agents.pi.extensions.pi-observational-memory = {
    enable = lib.mkEnableOption "tiered observational memory for Pi";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.extension;
      defaultText = lib.literalExpression "the pinned pi-observational-memory package";
      description = "Pinned pi-observational-memory extension package.";
    };

    config = lib.mkOption {
      type = json.type;
      default = {};
      description = "Configuration merged into Pi's observational-memory settings.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = !extCfg.enable || cfg.pi.enable;
          message = "programs.agents.pi.extensions.pi-observational-memory.enable requires programs.agents.pi.enable";
        }
      ];
    }

    (lib.mkIf (cfg.pi.enable && extCfg.enable) {
      programs.agents.pi.settings."observational-memory" = extCfg.config;
    })
  ]);
}
