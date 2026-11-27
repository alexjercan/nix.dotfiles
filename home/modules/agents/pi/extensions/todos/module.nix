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
  # todo_plan to append a nested plan atomically, or todo_add and
  # todo_add_subtodo for small changes. todo_list preserves tree order; request
  # history is opt-in via includeRequests. Mutations return affected tasks.
  # todo_update and todo_delete maintain the plan. `/todos` or Alt+T opens a list:
  # at most 10 todos are visible, including subtodos. Arrows or j/k scroll
  # with the cursor. Page Up/Down scroll by a page; Home/End jump to the ends.
  # Space closes or reopens a todo, and x deletes a todo with its subtodos.
  # A replacement is a new todo. The ledger follows the branch.
  # With open todos, a hidden review asks the agent whether useful progress is
  # possible. The first work tool after a review shows a "Resuming todo work"
  # card; inspecting todo_list alone does not. The card is UI-only and persists.
  # todo_stop(reason) stops reviews without changing task status. Successful
  # stops are hidden; errors remain visible. Prompt guidance suppresses redundant
  # closing replies, but allows new blockers or errors needing user attention.
  # The loop also ends when all todos close or after 5 reviews with no task change.
  # Queued messages, errors, and aborts are not nudged. A new user request or wake
  # starts a fresh activity; stopping does not disable other integrations.
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
