{pkgs, ...}: let
  macros = pkgs.vimUtils.buildVimPlugin {
    name = "tatr-nvim";
    src = pkgs.fetchFromGitHub {
      owner = "alexjercan";
      repo = "tatr.nvim";
      rev = "01a141bbcd58c4dd8b203a289470de27b0f0b93a";
      hash = "sha256-Z2wSjOw93wqR7lNcz/6WxHdk72/Z3KQhRaaCN/7Osz4=";
    };
  };
in {
  programs.nixvim = {
    extraPlugins = [
      macros
    ];

    extraConfigLua = ''
      require("tatr").setup();
    '';

    keymaps = [
      {
        mode = "n";
        key = "<leader>tn";
        action = ''<cmd>TatrNew<CR>'';
        options = {
          silent = true;
          desc = "Tatr New";
        };
      }
      {
        mode = "n";
        key = "<leader>tl";
        action = ''<cmd>TatrList<CR>'';
        options = {
          silent = true;
          desc = "Tatr List";
        };
      }
      {
        mode = "n";
        key = "<leader>ti";
        action = ''<cmd>TatrInsert<CR>'';
        options = {
          silent = true;
          desc = "Tatr Insert";
        };
      }
    ];
  };
}
