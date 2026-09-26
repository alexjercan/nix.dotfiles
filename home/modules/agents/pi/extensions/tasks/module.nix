{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.agents;
  extCfg = cfg.pi.extensions.tasks;
  self = import ./. {inherit pkgs;};
in {
  options.programs.agents.pi.extensions.tasks = {
    enable = lib.mkEnableOption "the session task ledger for Pi";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.extension;
      defaultText = lib.literalExpression "the local tasks extension package";
      description = "Local tasks extension package.";
    };
  };

  # The extension records each user prompt as P<n>. The agent uses the `tasks`
  # tool to add tasks for actionable work, add subtasks, change statuses, and
  # link superseded tasks. `/todos` or Alt+T opens a keyboard list: arrows or j/k
  # move, Space toggles completion, x archives, u restores, and v shows
  # archived tasks. Nothing is deleted. The ledger follows the session branch.
  # At the settle boundary, open tasks cause a reminder and continuation.
  # Aborted runs do not continue. For local checks, run `npm install`,
  # `npm test`, and `npm run typecheck` in this directory.
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !extCfg.enable || cfg.pi.enable;
        message = "programs.agents.pi.extensions.tasks.enable requires programs.agents.pi.enable";
      }
    ];
  };
}
