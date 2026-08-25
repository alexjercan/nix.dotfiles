{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.agents;
  toolCfg = cfg.codex;
in {
  options.programs.agents.codex = {
    enable = lib.mkEnableOption "the Codex CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llm-agents.codex;
      defaultText = lib.literalExpression "pkgs.llm-agents.codex";
      description = "The Codex package installed by the dotfiles.";
    };
  };

  config = lib.mkIf (cfg.enable && toolCfg.enable) {
    home.packages = [toolCfg.package];
  };
}
