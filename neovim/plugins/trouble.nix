{...}: {
  programs.nixvim = {
    plugins.trouble = {
      enable = true;
      luaConfig.post = ''
        local open_with_trouble = require("trouble.sources.telescope").open
        local telescope = require("telescope")

        telescope.setup({
          defaults = {
            mappings = {
              i = { ["<c-t>"] = open_with_trouble },
              n = { ["<c-t>"] = open_with_trouble },
            },
          },
        })
      '';
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<cr>";
        options = {desc = "Diagnostics (Trouble)";};
      }
      {
        mode = "n";
        key = "<leader>xX";
        action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
        options = {desc = "Buffer Diagnostics (Trouble)";};
      }
      {
        mode = "n";
        key = "<leader>cs";
        action = "<cmd>Trouble symbols toggle focus=false<cr>";
        options = {desc = "Symbols (Trouble)";};
      }
      {
        mode = "n";
        key = "<leader>cl";
        action = "<cmd>Trouble lsp toggle focus=false win.position=right<cr>";
        options = {desc = "LSP Definitions / references / ... (Trouble)";};
      }
      {
        mode = "n";
        key = "<leader>xL";
        action = "<cmd>Trouble loclist toggle<cr>";
        options = {desc = "Location List (Trouble)";};
      }
      {
        mode = "n";
        key = "<leader>xQ";
        action = "<cmd>Trouble qflist toggle<cr>";
        options = {desc = "Quickfix List (Trouble)";};
      }
    ];
  };
}
