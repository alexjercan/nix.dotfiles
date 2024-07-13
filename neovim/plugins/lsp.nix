{...}: {
  programs.nixvim = {
    plugins.fidget.enable = true;

    plugins.lsp = {
      enable = true;

      keymaps = {
        silent = true;

        diagnostic = {
          "vd" = "open_float";
          "[d" = "goto_next";
          "]d" = "goto_prev";
        };

        lspBuf = {
          "gd" = "definition";
          "K" = "hover";
          "<leader>vws" = "workspace_symbol";
          "<leader>vca" = "code_action";
          "<leader>vrr" = "references";
          "<leader>vrn" = "rename";
          "<C-h>" = "signature_help";
          "<leader>vmt" = "format";
        };
      };

      servers = {
        clangd.enable = true;
        nixd.enable = true;
        pylsp.enable = true;
      };
    };

    plugins.cmp = {
      enable = true;

      settings = {
        sources = [
          {name = "path";}
          {name = "nvim_lsp";}
          {name = "nvim_lua";}
          {
            name = "luasnip";
            keyword_length = 2;
          }
          {
            name = "buffer";
            keyword_length = 3;
          }
        ];

        mapping = {
          "<C-Space>" = "cmp.mapping.complete()";
          "<C-u>" = "cmp.mapping.scroll_docs(-4)";
          "<C-d>" = "cmp.mapping.scroll_docs(4)";
          "<C-p>" = "cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select })";
          "<C-n>" = "cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select })";
          "<C-y>" = "cmp.mapping.confirm({ select = true })";
          "<CR>" = "nil";
          "<Tab>" = "nil";
          "<S-Tab>" = "nil";
        };
      };
    };
  };
}
