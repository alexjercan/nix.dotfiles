{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.agents;
  extCfg = cfg.pi.extensions.pi-subagents;
  self = import ./. {inherit pkgs;};
in {
  options.programs.agents.pi.extensions.pi-subagents = {
    enable = lib.mkEnableOption "observable Pi and Claude subagents";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.extension;
      defaultText = lib.literalExpression "the pinned pi-subagents package";
      description = "Pinned pi-subagents extension package.";
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional subagent YAML configuration installed for Pi.";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.pi.enable && extCfg.enable && extCfg.configFile != null) {
    home.file.".pi/agent/subagents.yaml".source = extCfg.configFile;
  };
}
