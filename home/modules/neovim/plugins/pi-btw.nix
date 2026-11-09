{pkgs, ...}: let
  # Share the Pi pin so both ends use the same bridge protocol.
  piBtw = import ../../agents/pi/extensions/pi-btw {inherit pkgs;};
  plugin = pkgs.vimUtils.buildVimPlugin {
    name = "pi-btw-nvim";
    src = piBtw.source + "/nvim";
  };
in {
  programs.nixvim = {
    extraPlugins = [plugin];

    extraConfigLua = ''
      require("pi_btw").setup();
    '';

    keymaps = [
      {
        mode = ["n" "x"];
        key = "<leader>n";
        action = ":BtwComment<CR>";
        options = {
          silent = true;
          desc = "Queue Pi comment";
        };
      }
      {
        mode = ["n" "x"];
        key = "<leader>b";
        action = ":BtwAsk<CR>";
        options = {
          silent = true;
          desc = "Ask Pi side question";
        };
      }
      {
        mode = "n";
        key = "<leader>q";
        action = "<cmd>BtwQueue<CR>";
        options = {
          silent = true;
          desc = "Open Pi queue";
        };
      }
      {
        mode = "n";
        key = "<leader>f";
        action = "<cmd>BtwFollowup<CR>";
        options = {
          silent = true;
          desc = "Follow up in BTW thread";
        };
      }
      {
        mode = "n";
        key = "<leader>p";
        action = "<cmd>BtwSend<CR>";
        options = {
          silent = true;
          desc = "Send BTW buffer to Pi";
        };
      }
    ];
  };
}
