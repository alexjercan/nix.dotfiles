{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.agents;

  # Defaults come from `pkgs.llm-agents`, so pkgs must carry the
  # llm-agents.nix `shared-nixpkgs` overlay. It tracks upstream agent releases
  # much closer than nixpkgs does.
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
    ++ lib.optional cfg.opencode.enable cfg.opencode.package;
in {
  options.programs.agents = {
    agentBrowser = mkPackageToolOptions {
      name = "agent-browser";
      package = pkgs.llm-agents.agent-browser;
      packageDefault = "pkgs.llm-agents.agent-browser";
    };

    claudeCode = mkPackageToolOptions {
      name = "Claude Code";
      package = pkgs.llm-agents.claude-code;
      packageDefault = "pkgs.llm-agents.claude-code";
    };

    codex = mkPackageToolOptions {
      name = "Codex";
      package = pkgs.llm-agents.codex;
      packageDefault = "pkgs.llm-agents.codex";
    };

    opencode = mkPackageToolOptions {
      name = "OpenCode";
      package = pkgs.llm-agents.opencode;
      packageDefault = "pkgs.llm-agents.opencode";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = toolPackages;
  };
}
