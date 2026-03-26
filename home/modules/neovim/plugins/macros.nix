{pkgs, ...}: let
  macros = pkgs.vimUtils.buildVimPlugin {
    name = "macros-nvim";
    src = pkgs.fetchFromGitHub {
      owner = "alexjercan";
      repo = "macros.nvim";
      rev = "ba49f9aed179aa2619ddc0021f0c190b94fe212f";
      hash = "sha256-M+2v5migHdxspnus/t5933avJ634bXffJIYNLXebZzs=";
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
        action = ''<cmd>MacrosQuery<CR>'';
        options = {
          silent = true;
          desc = "Macros Query";
        };
      }
    ];
  };
}
