{pkgs, ...}: let
  macros = pkgs.vimUtils.buildVimPlugin {
    name = "macros-nvim";
    src = pkgs.fetchFromGitHub {
      owner = "alexjercan";
      repo = "macros.nvim";
      rev = "ce85e483ac6eaa8e19a9717a09523a4f3fe7ebf4";
      hash = "sha256-+R9FA/kDFIuynbcSLn76AyXQQLrDU65JwFhWvsIFAqM=";
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
