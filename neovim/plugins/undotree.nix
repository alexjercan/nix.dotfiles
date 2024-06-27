{...}: {
  programs.nixvim = {
    plugins.undotree = {
      enable = true;
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>u";
        action = "<cmd>UndotreeToggle<CR>";
        options = {desc = "Undo Tree";};
      }
    ];
  };
}
