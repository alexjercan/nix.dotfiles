{pkgs, ...}: let
  _99 = pkgs.vimUtils.buildVimPlugin {
    name = "99";
    src = pkgs.fetchFromGitHub {
      owner = "ThePrimeagen";
      repo = "99";
      rev = "34a81b09656d2daa87f1d689550742928a4eb709";
      hash = "sha256-zgkicopAnEYnkAOJ8e77CCiRE2amSAEYRkhOrcSf7rg=";
    };
  };
in {
  programs.nixvim = {
    extraPlugins = [
      _99
    ];

    extraConfigLua = ''
      local _99 = require("99")

      local cwd = vim.uv.cwd()
      local basename = vim.fs.basename(cwd)
      _99.setup({
          -- provider = _99.Providers.ClaudeCodeProvider,  -- default: OpenCodeProvider
          logger = {
              level = _99.DEBUG,
              path = "/tmp/" .. basename .. ".99.debug",
              print_on_error = true,
          },
          -- WARNING: must stay inside the CWD, else claude code and opencode
          -- hit permission errors and generation fails.
          tmp_dir = "./tmp",

          completion = {
              -- cursor_rules = "<custom path to cursor rules>"

              custom_rules = {
                "scratch/custom_rules/",
              },

              files = {
                  -- enabled = true,
                  -- max_file_size = 102400,
                  -- max_files = 5000,
                  -- exclude = { ".env", ".env.*", "node_modules", ".git", ... },
              },

              source = "cmp",
          },

          --- CWD-sensitive upstream lookup.
          md_files = {
              "AGENT.md",
          },
      })

      vim.keymap.set("v", "<leader>9v", function()
          _99.visual()
      end)

      vim.keymap.set("n", "<leader>9x", function()
          _99.stop_all_requests()
      end)

      vim.keymap.set("n", "<leader>9s", function()
          _99.search()
      end)

      vim.keymap.set("n", "<leader>9m", function()
        require("99.extensions.telescope").select_model()
      end)

      vim.keymap.set("n", "<leader>9p", function()
        require("99.extensions.telescope").select_provider()
      end)
    '';
  };
}
