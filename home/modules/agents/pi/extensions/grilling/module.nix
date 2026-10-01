{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.agents;
  extCfg = cfg.pi.extensions.grilling;
  self = import ./. {inherit pkgs;};
in {
  options.programs.agents.pi.extensions.grilling = {
    enable = lib.mkEnableOption "session grilling mode for Pi";
    package = lib.mkOption {
      type = lib.types.package;
      default = self.extension;
      defaultText = lib.literalExpression "the local grilling extension package";
      description = "Local grilling extension package.";
    };
  };

  # /grill [on|off|status] controls the branch-local planning mode. Outside
  # grilling, ask_user is blocked and the agent records consequential choices
  # with record_decision. /decisions shows those choices for later review.
  # This guard covers Pi ask_user calls; free-text questions and other tools
  # rely on the injected instructions.
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !extCfg.enable || cfg.pi.enable;
        message = "programs.agents.pi.extensions.grilling.enable requires programs.agents.pi.enable";
      }
      {
        assertion = !extCfg.enable || cfg.pi.extensions.pi-ask-user.enable;
        message = "programs.agents.pi.extensions.grilling.enable requires pi-ask-user";
      }
    ];
  };
}
