{nixvim, ...}: {
  imports = [
    nixvim.homeManagerModules.nixvim
    ./remap.nix
    ./set.nix
    ./autocmd.nix
    ./plugins
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    vimdiffAlias = true;

    viAlias = true;
    vimAlias = true;
  };
}
