{...}: {
  programs.nixvim = {
    globals = {
      netrw_browse_split = 0;
      netrw_banner = 0;
      netrw_winsize = 25;
    };

    opts = {
      guicursor = "";

      nu = true;
      relativenumber = true;

      errorbells = false;

      tabstop = 4;
      softtabstop = 4;
      shiftwidth = 4;
      expandtab = true;

      smartindent = true;

      wrap = false;

      swapfile = false;
      backup = false;
      undofile = true;

      hlsearch = false;
      incsearch = true;

      termguicolors = true;

      scrolloff = 8;
      signcolumn = "yes";

      # Give more space for displaying messages.
      cmdheight = 1;

      # Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
      # delays and poor user experience.
      updatetime = 50;

      colorcolumn = "80";
    };
  };
}
