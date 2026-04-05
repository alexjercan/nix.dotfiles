{pkgs, ...}: let
  macros = pkgs.vimUtils.buildVimPlugin {
    name = "macros-nvim";
    src = pkgs.fetchFromGitHub {
      owner = "alexjercan";
      repo = "macros.nvim";
      rev = "8bca1c13ea298994bc46d263c6144ad9f82a2fe5";
      hash = "sha256-rfSDd4xBbljnSP8/YXlF/ZNdSjk1YeDU+SmMrx1asas=";
    };
  };
in {
  programs.nixvim = {
    extraPlugins = [
      macros
    ];

    extraConfigLua = ''
      require("macros").setup();
    '';

    keymaps = [
      {
        mode = "n";
        key = "<leader>mm";
        action = ''<cmd>Macros<CR>'';
        options = {
          silent = true;
          desc = "Macros";
        };
      }
      {
        mode = "n";
        key = "<leader>mi";
        action = ''<cmd>MacrosInsert<CR>'';
        options = {
          silent = true;
          desc = "Macros Insert";
        };
      }
      {
        mode = "n";
        key = "<leader>mq";
        action = ''<cmd>MacrosQuery2<CR>'';
        options = {
          silent = true;
          desc = "Macros Query";
        };
      }
      {
        mode = "n";
        key = "<leader>mt";
        action = ''<cmd>MacrosTelescope<CR>'';
        options = {
          silent = true;
          desc = "Macros Query Telescope";
        };
      }
    ];
  };
}
