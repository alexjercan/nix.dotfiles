{pkgs, ...}: let
  # Share the Pi pin so both ends use the same bridge protocol.
  piBtw = import ../../agents/pi/extensions/pi-btw {inherit pkgs;};
in {
  programs.nixvim = {
    imports = [(piBtw.source + "/nix/nixvim.nix")];

    plugins.pi-btw = {
      enable = true;
      settings = {};
    };

    keymaps = [
      {
        mode = ["n" "x"];
        key = "<leader>bn";
        action = ":BtwNote<CR>";
        options = {
          silent = true;
          desc = "BTW: annotate into prompt";
        };
      }
      {
        mode = "n";
        key = "<leader>be";
        action = "<cmd>BtwPrompt<CR>";
        options = {
          silent = true;
          desc = "BTW: edit prompt";
        };
      }
      {
        mode = "n";
        key = "<leader>bp";
        action = "<cmd>BtwSendRequest<CR>";
        options = {
          silent = true;
          desc = "BTW: send prompt to Pi";
        };
      }
      {
        mode = "n";
        key = "<leader>bt";
        action = "<cmd>BtwSendThread<CR>";
        options = {
          silent = true;
          desc = "BTW: send prompt to thread";
        };
      }
      {
        mode = "n";
        key = "<leader>bo";
        action = "<cmd>BtwThreads<CR>";
        options = {
          silent = true;
          desc = "BTW: open a thread";
        };
      }
      {
        mode = ["n" "x"];
        key = "<leader>bT";
        action = ":BtwAsk<CR>";
        options = {
          silent = true;
          desc = "BTW: quick ask thread";
        };
      }
      {
        mode = ["n" "x"];
        key = "<leader>bP";
        action = ":BtwRequest<CR>";
        options = {
          silent = true;
          desc = "BTW: quick request to Pi";
        };
      }
    ];
  };
}
