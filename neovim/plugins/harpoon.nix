{...}: {
  programs.nixvim = {
    plugins.harpoon = {
      enable = true;

      keymapsSilent = true;

      keymaps = {
        addFile = "<leader>H";
        toggleQuickMenu = "<leader>h";
        navFile = {
          "1" = "<leader>1";
          "2" = "<leader>2";
          "3" = "<leader>3";
          "4" = "<leader>4";
        };
      };
    };
  };
}
