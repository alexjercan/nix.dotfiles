{...}: {
  programs.nixvim = {
    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>mv";
        action.__raw = ''vim.cmd.Ex'';
        options = {desc = "File Navigator";};
      }
      # -- cool move line in visual mode
      {
        mode = "v";
        key = "J";
        action = ":m '>+1<CR>gv=gv";
      }
      {
        mode = "v";
        key = "K";
        action = ":m '<-2<CR>gv=gv";
      }
      # -- don't ask
      {
        mode = "n";
        key = "Y";
        action = "yg$";
      }
      # -- better moves
      {
        mode = "n";
        key = "J";
        action = "mzJ`z";
      }
      {
        mode = "n";
        key = "<C-d>";
        action = "<C-d>zz";
      }
      {
        mode = "n";
        key = "<C-u>";
        action = "<C-u>zz";
      }
      {
        mode = "n";
        key = "n";
        action = "nzzzv";
      }
      {
        mode = "n";
        key = "N";
        action = "Nzzzv";
      }
      # -- greatest remap ever
      {
        mode = "x";
        key = "<leader>p";
        action = "\"_dP";
        options = {desc = "Paste over";};
      }
      # -- next greatest remap ever : asbjornHaland
      {
        mode = ["n" "v"];
        key = "<leader>y";
        action = "\"+y";
        options = {desc = "Copy to clipboard";};
      }
      {
        mode = "n";
        key = "<leader>Y";
        action = "\"+Y";
        options = {desc = "Copy line to clipboard";};
      }
      # -- This is going to get me cancelled
      {
        mode = "i";
        key = "<C-c>";
        action = "<Esc>";
      }
      # -- never press Q
      {
        mode = "n";
        key = "Q";
        action = "<nop>";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<cmd>cnext<CR>zz";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<cmd>cprev<CR>zz";
      }
      {
        mode = "n";
        key = "<leader>k";
        action = "<cmd>lnext<CR>zz";
        options = {desc = "Next location list";};
      }
      {
        mode = "n";
        key = "<leader>j";
        action = "<cmd>lprev<CR>zz";
        options = {desc = "Previous location list";};
      }
      # -- for fast repalce
      {
        mode = "n";
        key = "<leader>s";
        action = ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>";
        options = {desc = "Replace word under cursor";};
      }
      # -- do this on the bash script you download from the internet
      {
        mode = "n";
        key = "<leader>x";
        action = "<cmd>!chmod +x %<CR>";
        options = {
          silent = true;
          desc = "Make file executable";
        };
      }
      # -- for when you have to share the screen and they ask you
      # -- "what does the code from the line 10 mean?"
      {
        mode = "n";
        key = "<leader>mnu";
        action = ":set rnu!<CR>";
        options = {desc = "Toggle relative numbers";};
      }
      # -- don't be a pussy, just use hjkl
      {
        mode = "i";
        key = "<Up>";
        action = "<C-o>:echom \"--> k <-- \"<CR>";
      }
      {
        mode = "i";
        key = "<Down>";
        action = "<C-o>:echom \"--> j <-- \"<CR>";
      }
      {
        mode = "i";
        key = "<Right>";
        action = "<C-o>:echom \"--> k <-- \"<CR>";
      }
      {
        mode = "i";
        key = "<Left>";
        action = "<C-o>:echom \"--> h <-- \"<CR>";
      }
      {
        mode = "n";
        key = "<Up>";
        action = ":echom \"--> k <-- \"<CR>";
      }
      {
        mode = "n";
        key = "<Down>";
        action = ":echom \"--> j <-- \"<CR>";
      }
      {
        mode = "n";
        key = "<Right>";
        action = ":echom \"--> k <-- \"<CR>";
      }
      {
        mode = "n";
        key = "<Left>";
        action = ":echom \"--> h <-- \"<CR>";
      }


      # -- TODO: move this to harpoon
      { mode = "n"; key = "<leader>H"; action.__raw = "function() require'harpoon':list():add() end"; }
      { mode = "n"; key = "<leader>h"; action.__raw = "function() require'harpoon'.ui:toggle_quick_menu(require'harpoon':list()) end"; }
      { mode = "n"; key = "<leader>1"; action.__raw = "function() require'harpoon':list():select(1) end"; }
      { mode = "n"; key = "<leader>2"; action.__raw = "function() require'harpoon':list():select(2) end"; }
      { mode = "n"; key = "<leader>3"; action.__raw = "function() require'harpoon':list():select(3) end"; }
      { mode = "n"; key = "<leader>4"; action.__raw = "function() require'harpoon':list():select(4) end"; }
    ];
  };
}
