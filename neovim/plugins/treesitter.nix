{...}: {
  programs.nixvim = {
    plugins.treesitter = {
      enable = true;
    };

    plugins.treesitter-context = {
      enable = true;

      settings = {
        enable = true;
        mode = "cursor";
        max_lines = 3;
        trim_scope = "inner";
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>ut";
        action = "<cmd>TSContextToggle<CR>";
        options = {desc = "Toggle Treesitter Context";};
      }
    ];
  };
}
