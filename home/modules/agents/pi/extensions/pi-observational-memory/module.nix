{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.agents;
  extCfg = cfg.pi.extensions.pi-observational-memory;
  self = import ./. {inherit pkgs;};
in {
  # The extension reads its own configuration from the `observational-memory`
  # key of pi's settings.json, so it needs no file of its own: declare it
  # through `programs.agents.pi.settings."observational-memory"`.
  options.programs.agents.pi.extensions.pi-observational-memory = {
    enable = lib.mkEnableOption "tiered observational memory for Pi";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.extension;
      defaultText = lib.literalExpression "the pinned pi-observational-memory package";
      description = "Pinned pi-observational-memory extension package.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !extCfg.enable || cfg.pi.enable;
        message = "programs.agents.pi.extensions.pi-observational-memory.enable requires programs.agents.pi.enable";
      }
    ];
  };
}
