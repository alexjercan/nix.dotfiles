{...}: {
  programs.nixvim = {
    plugins.copilot-vim = {
      enable = true;
    };

    globals = {
        copilot_enabled = false;
    };
  };
}

