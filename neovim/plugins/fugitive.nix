{...}: {
  programs.nixvim = {
    plugins.fugitive = {
      enable = true;
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>gs";
        action.__raw = ''vim.cmd.Git'';
        options = {desc = "Git Status";};
      }
      {
        mode = "n";
        key = "gh";
        action = "<cmd>diffget //2>CR>";
      }
      {
        mode = "n";
        key = "gl";
        action = "<cmd>diffget //3>CR>";
      }
      {
        mode = "n";
        key = "<leader>gt";
        action = '':Git push -u origin '';
        options = {desc = "Git Push Tracking";};
      }
      {
        mode = "n";
        key = "<leader>gp";
        action = ''<cmd>Git push<CR>'';
        options = {desc = "Git Push";};
      }
    ];
  };
}
