{pkgs, ...}: let
  treesitter-c3-grammar = pkgs.tree-sitter.buildGrammar {
    language = "c3";
    version = "0.0.0+rev=c6b1bae";
    src = pkgs.fetchFromGitHub {
      owner = "c3lang";
      repo = "tree-sitter-c3";
      rev = "c6b1bae4d575f91e5c6c3c4af93bbec4e543ac5e";
      hash = "sha256-vaS18whZ5FQkRvHIZvJLpKG+NO+5nHKNFxgISIV+7rU=";
    };
  };
in {
  programs.nixvim = {
    plugins.treesitter = {
      enable = true;
      grammarPackages =
        pkgs.vimPlugins.nvim-treesitter.passthru.allGrammars
        ++ [
          treesitter-c3-grammar
        ];

      settings = {
        highlight.enable = true;
      };
    };

    extraConfigLua = ''
      do
        local parser_config = require("nvim-treesitter.parsers")
        parser_config.c3 = {
          install_info = {
            url = "${treesitter-c3-grammar}",
            files = {"src/parser.c", "src/scanner.c"},
            branch = "main",
          },
          filetype = "c3",
        }
      end
    '';

    extraPlugins = [
      treesitter-c3-grammar
    ];

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
