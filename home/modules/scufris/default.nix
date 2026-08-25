{config, ...}: {
  imports = [./i3.nix];

  programs.scufris = {
    enable = true;
    piPackage = config.programs.agents.pi.finalPackage;

    voice = {
      enable = true;
      popup.enable = true;
    };

    desktop = {
      enable = true;
      stt.endpoint = "http://127.0.0.1:10301/inference";
    };
  };
}
