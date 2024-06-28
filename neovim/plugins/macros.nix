{pkgs, ...}: let
  macros = pkgs.vimUtils.buildVimPlugin {
    name = "macros-nvim";
    src = pkgs.fetchFromGitHub {
      owner = "alexjercan";
      repo = "macros.nvim";
      rev = "078b8dc2c67cc4bbd7f77113cdb2fbfb939e652f";
      hash = "sha256-DrPCgsTzQNOx/UxexsmLaM2hTzlopu6qBbERVrzUx9I=";
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
          desc = "Macros";
        };
      }
    ];
  };
}
