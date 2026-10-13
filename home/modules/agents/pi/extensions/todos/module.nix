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

  # The extension records each user prompt as P<n>. The agent uses separate
  # todo_list, todo_add, todo_add_subtodo, todo_update, and todo_delete tools
  # to track work in this session. `/todos` or Alt+T opens a keyboard list:
  # arrows or j/k move, Space closes or reopens a todo, and x deletes a todo
  # with its subtodos. A replacement is a new todo. The ledger follows the
  # branch.
  # While todos are open, the agent is told to continue when it stops. The loop
  # ends when all todos are closed, when the agent makes no tool calls after a
  # nudge, or after 5 nudges with no todo change. It does not nudge while a
  # message is queued. A later wake, for example from a finished job, starts a
  # new activity with a fresh budget.
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
