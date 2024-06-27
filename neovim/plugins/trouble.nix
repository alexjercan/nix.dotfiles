{...}: {
  programs.nixvim = {
    plugins.trouble = {
      enable = true;
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble<CR>";
        options = {desc = "Toggle Treesitter Context";};
      }
      {
        mode = "n";
        key = "<leader>xw";
        action = "<cmd>Trouble workspace_diagnostics<CR>";
        options = {desc = "Toggle Treesitter Context";};
      }
      {
        mode = "n";
        key = "<leader>xd";
        action = "<cmd>Trouble document_diagnostics<CR>";
        options = {desc = "Toggle Treesitter Context";};
      }
      {
        mode = "n";
        key = "<leader>xq";
        action = "<cmd>Trouble quickfix<CR>";
        options = {desc = "Toggle Treesitter Context";};
      }
      {
        mode = "n";
        key = "<leader>xl";
        action = "<cmd>Trouble loclist<CR>";
        options = {desc = "Toggle Treesitter Context";};
      }
    ];
  };
}
