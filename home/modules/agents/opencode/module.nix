{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.agents;
  toolCfg = cfg.opencode;
in {
  options.programs.agents.opencode = {
    enable = lib.mkEnableOption "the OpenCode CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llm-agents.opencode;
      defaultText = lib.literalExpression "pkgs.llm-agents.opencode";
      description = "The OpenCode package installed by the dotfiles.";
    };
  };

  config = lib.mkIf (cfg.enable && toolCfg.enable) {
    home.packages = [toolCfg.package];
  };
}
