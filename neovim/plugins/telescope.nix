{...}: {
  programs.nixvim = {
    plugins.telescope = {
      enable = true;

      keymaps = {
        # Find files using Telescope command-line sugar.
        "<leader>ff" = {
          action = "find_files";
          options = {desc = "Find files";};
        };
        "<leader>fg" = {
          action = "live_grep";
          options = {desc = "Live grep";};
        };
        "<leader>fb" = {
          action = "buffers";
          options = {desc = "Buffers";};
        };
        "<leader>fh" = {
          action = "help_tags";
          options = {desc = "Help Tags";};
        };
      };

      settings.defaults = {
        file_ignore_patterns = [
          "^.git/"
          "^.mypy_cache/"
          "^__pycache__/"
          "^output/"
          "^data/"
          "%.ipynb"
        ];
        set_env.COLORTERM = "truecolor";
      };
    };
  };
}
