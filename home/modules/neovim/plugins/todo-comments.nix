{...}: {
  programs.nixvim = {
    plugins.todo-comments = {
      enable = true;

      keymaps = {
        todoTrouble.key = "<leader>xt";
        todoTelescope.key = "<leader>st";
      };
    };
  };
}
