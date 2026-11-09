{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.agents;
  extCfg = cfg.pi.extensions.pi-btw;
  self = import ./. {inherit pkgs;};
in {
  options.programs.agents.pi.extensions.pi-btw = {
    enable = lib.mkEnableOption "Pi side threads and the Neovim bridge";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.extension;
      defaultText = lib.literalExpression "the pinned pi-btw package";
      description = "Pinned pi-btw extension package.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !extCfg.enable || cfg.pi.enable;
        message = "programs.agents.pi.extensions.pi-btw.enable requires programs.agents.pi.enable";
      }
    ];
  };
}
