{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.agents;
  toolCfg = cfg.claudeCode;
in {
  options.programs.agents.claudeCode = {
    enable = lib.mkEnableOption "the Claude Code CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llm-agents.claude-code;
      defaultText = lib.literalExpression "pkgs.llm-agents.claude-code";
      description = "The Claude Code package installed by the dotfiles.";
    };
  };

  config = lib.mkIf (cfg.enable && toolCfg.enable) {
    home.packages = [toolCfg.package];
  };
}
