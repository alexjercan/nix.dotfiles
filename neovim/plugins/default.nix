{pkgs, ...}: {
  imports = [
    ./telescope.nix
    ./fugitive.nix
    ./harpoon.nix
    ./todo-comments.nix
    ./treesitter.nix
    ./trouble.nix
    ./undotree.nix
    ./lsp.nix
    ./macros.nix
    ./copilot.nix
  ];

  programs.nixvim = {
    extraPlugins = [pkgs.vimPlugins.gruber-darker-nvim];
    colorscheme = "gruber-darker";

    plugins.surround.enable = true;
  };
}
