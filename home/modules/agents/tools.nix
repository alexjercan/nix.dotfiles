{
  agentPackages,
  toolSkills,
}: {
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.agents;

  mkPackageToolOptions = {
    name,
    package,
    packageDefault,
  }: {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the dotfiles install ${name}.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
      defaultText = lib.literalExpression packageDefault;
      description = "The ${name} package installed by the dotfiles.";
    };
  };

  toolPackages =
    lib.optional cfg.agentBrowser.enable cfg.agentBrowser.package
    ++ lib.optional cfg.claudeCode.enable cfg.claudeCode.package
    ++ lib.optional cfg.codex.enable cfg.codex.package
    ++ lib.optional cfg.knowledge.enable cfg.knowledge.package
    ++ lib.optional cfg.opencode.enable cfg.opencode.package
    ++ lib.optional cfg.plannotator.enable cfg.plannotator.package;
in {
  options.programs.agents = {
    agentBrowser = mkPackageToolOptions {
      name = "agent-browser";
      package = pkgs.agent-browser;
      packageDefault = "pkgs.agent-browser";
    };

    claudeCode = mkPackageToolOptions {
      name = "Claude Code";
      package = pkgs.claude-code;
      packageDefault = "pkgs.claude-code";
    };

    codex = mkPackageToolOptions {
      name = "Codex";
      package = pkgs.codex;
      packageDefault = "pkgs.codex";
    };

    knowledge =
      mkPackageToolOptions {
        name = "knowledge";
        package = agentPackages.knowledge;
        packageDefault = "agentPackages.knowledge";
      }
      // {
        directory = lib.mkOption {
          type = lib.types.str;
          default = "${config.xdg.dataHome}/agents/knowledge";
          defaultText = lib.literalExpression ''"''${config.xdg.dataHome}/agents/knowledge"'';
          description = "Directory for durable local agent lessons.";
        };
      };

    opencode = mkPackageToolOptions {
      name = "OpenCode";
      package = pkgs.opencode;
      packageDefault = "pkgs.opencode";
    };

    plannotator = mkPackageToolOptions {
      name = "Plannotator";
      package = agentPackages.plannotator;
      packageDefault = "agentPackages.plannotator";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      programs.agents.internalSkills =
        lib.optionalAttrs cfg.knowledge.enable {knowledge = toolSkills.knowledge;};

      home.packages = toolPackages;
    }

    (lib.mkIf cfg.knowledge.enable {
      home.sessionVariables.AGENTS_KNOWLEDGE_DIR = cfg.knowledge.directory;
    })
  ]);
}
