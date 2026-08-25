{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.agents;
  extCfg = cfg.pi.extensions.plannotator;
  self = import ./. {inherit pkgs;};
in {
  options.programs.agents.pi.extensions.plannotator = {
    enable = lib.mkEnableOption "the Plannotator Pi extension and the CLI it drives";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.extension;
      defaultText = lib.literalExpression "the pinned @plannotator/pi-extension package";
      description = "Pinned @plannotator/pi-extension package.";
    };

    cli = lib.mkOption {
      type = lib.types.package;
      default = self.binary;
      defaultText = lib.literalExpression "the Plannotator release that matches the extension";
      description = "Plannotator CLI that the extension starts.";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.pi.enable && extCfg.enable) {
    home.packages = [extCfg.cli];
  };
}
