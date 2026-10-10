{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.agents;
  extCfg = cfg.pi.extensions.todos;
  self = import ./. {inherit pkgs;};
in {
  options.programs.agents.pi.extensions.todos = {
    enable = lib.mkEnableOption "session todos for Pi";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.extension;
      defaultText = lib.literalExpression "the local todos extension package";
      description = "Local todos extension package.";
    };
  };

  # The extension records each user prompt as P<n>. The agent uses the `todos`
  # tool to track work in this session. `/todos` or Alt+T opens a keyboard list:
  # arrows or j/k move, Space toggles completion, x archives, u restores, and v
  # shows archived todos. Nothing is deleted. The ledger follows the branch.
  # Todos record progress; they never continue or retry an agent run.
  # For local checks, run `npm install`,
  # `npm test`, and `npm run typecheck` in this directory.
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !extCfg.enable || cfg.pi.enable;
        message = "programs.agents.pi.extensions.todos.enable requires programs.agents.pi.enable";
      }
    ];
  };
}
