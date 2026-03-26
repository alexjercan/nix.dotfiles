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

      -- For logging that is to a file if you wish to trace through requests
      -- for reporting bugs, i would not rely on this, but instead the provided
      -- logging mechanisms within 99.  This is for more debugging purposes
      local cwd = vim.uv.cwd()
      local basename = vim.fs.basename(cwd)
      _99.setup({
          -- provider = _99.Providers.ClaudeCodeProvider,  -- default: OpenCodeProvider
          logger = {
              level = _99.DEBUG,
              path = "/tmp/" .. basename .. ".99.debug",
              print_on_error = true,
          },
          -- When setting this to something that is not inside the CWD tools
          -- such as claude code or opencode will have permission issues
          -- and generation will fail refer to tool documentation to resolve
          -- https://opencode.ai/docs/permissions/#external-directories
          -- https://code.claude.com/docs/en/permissions#read-and-edit
          tmp_dir = "./tmp",

          --- Completions: #rules and @files in the prompt buffer
          completion = {
              -- I am going to disable these until i understand the
              -- problem better.  Inside of cursor rules there is also
              -- application rules, which means i need to apply these
              -- differently
              -- cursor_rules = "<custom path to cursor rules>"

              --- A list of folders where you have your own SKILL.md
              --- Expected format:
              --- /path/to/dir/<skill_name>/SKILL.md
              ---
              --- Example:
              --- Input Path:
              --- "scratch/custom_rules/"
              ---
              --- Output Rules:
              --- {path = "scratch/custom_rules/vim/SKILL.md", name = "vim"},
              --- ... the other rules in that dir ...
              ---
              custom_rules = {
                "scratch/custom_rules/",
              },

              --- Configure @file completion (all fields optional, sensible defaults)
              files = {
                  -- enabled = true,
                  -- max_file_size = 102400,     -- bytes, skip files larger than this
                  -- max_files = 5000,            -- cap on total discovered files
                  -- exclude = { ".env", ".env.*", "node_modules", ".git", ... },
              },

              --- What autocomplete you use.
              source = "cmp",
          },

          --- WARNING: if you change cwd then this is likely broken
          --- ill likely fix this in a later change
          ---
          --- md_files is a list of files to look for and auto add based on the location
          --- of the originating request.  That means if you are at /foo/bar/baz.lua
          --- the system will automagically look for:
          --- /foo/bar/AGENT.md
          --- /foo/AGENT.md
          --- assuming that /foo is project root (based on cwd)
          md_files = {
              "AGENT.md",
          },
      })

      -- take extra note that i have visual selection only in v mode
      -- technically whatever your last visual selection is, will be used
      -- so i have this set to visual mode so i dont screw up and use an
      -- old visual selection
      --
      -- likely ill add a mode check and assert on required visual mode
      -- so just prepare for it now
      vim.keymap.set("v", "<leader>9v", function()
          _99.visual()
      end)

      --- if you have a request you dont want to make any changes, just cancel it
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
