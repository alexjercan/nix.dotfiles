{
  config,
  lib,
  ...
}: let
  cfg = config.programs.agents;
in {
  # One directory per agent. The CLI packages default to `pkgs.llm-agents`, so
  # pkgs must carry the llm-agents.nix `shared-nixpkgs` overlay. It tracks
  # upstream agent releases much closer than nixpkgs does.
  imports = [
    ./agent-browser/module.nix
    ./claude-code/module.nix
    ./codex/module.nix
    ./opencode/module.nix
    ./pi/module.nix
  ];

  options.programs.agents = {
    enable = lib.mkEnableOption "the agent workflow workspace";

    agentsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Source AGENTS.md file, or null to deploy no global instructions.";
      example = lib.literalExpression "./AGENTS.md";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.agentsFile != null) {
    home.file = {
      "AGENTS.md".source = cfg.agentsFile;
      # Claude Code reads its own path, so point it at the single source.
      ".claude/CLAUDE.md".text = ''
        @~/AGENTS.md
      '';
      ".codex/AGENTS.md".source = cfg.agentsFile;
    };
  };
}
