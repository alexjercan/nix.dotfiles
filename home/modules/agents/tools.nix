{
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
    ++ lib.optional cfg.opencode.enable cfg.opencode.package;
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

    opencode = mkPackageToolOptions {
      name = "OpenCode";
      package = pkgs.opencode;
      packageDefault = "pkgs.opencode";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = toolPackages;
  };
}
