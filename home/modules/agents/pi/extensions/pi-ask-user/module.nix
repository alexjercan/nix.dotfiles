{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.agents;
  extCfg = cfg.pi.extensions.pi-ask-user;
  self = import ./. {inherit pkgs;};
in {
  options.programs.agents.pi.extensions.pi-ask-user = {
    enable = lib.mkEnableOption "the interactive ask_user tool for Pi";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.extension;
      defaultText = lib.literalExpression "the pinned pi-ask-user package";
      description = "Pinned pi-ask-user extension package.";
    };
  };

  # The extension reads every preference from PI_ASK_USER_* environment
  # variables and its defaults already match what this configuration wants.
  # PI_ASK_USER_EMIT_FULL_EVENTS in particular stays unset: enabling it would
  # broadcast the answers to every other installed extension.
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !extCfg.enable || cfg.pi.enable;
        message = "programs.agents.pi.extensions.pi-ask-user.enable requires programs.agents.pi.enable";
      }
    ];
  };
}
