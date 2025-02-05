{pkgs, ...}: {
  programs.nixvim = {
    plugins.copilot-vim = {
      enable = true;
      package = pkgs.vimPlugins.copilot-vim;
    };

    globals = {
      copilot_enabled = false;
    };
  };
}
