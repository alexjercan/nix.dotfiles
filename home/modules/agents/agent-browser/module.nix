{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.agents;
  toolCfg = cfg.agentBrowser;
in {
  options.programs.agents.agentBrowser = {
    enable = lib.mkEnableOption "the agent-browser CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llm-agents.agent-browser;
      defaultText = lib.literalExpression "pkgs.llm-agents.agent-browser";
      description = "The agent-browser package installed by the dotfiles.";
    };
  };

  config = lib.mkIf (cfg.enable && toolCfg.enable) {
    home.packages = [toolCfg.package];
  };
}
