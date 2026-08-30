{config, ...}: {
  programs.scufris = {
    # Keep the deployment dormant until an API-compatible release is pinned.
    enable = false;
    piPackage = config.programs.agents.pi.finalPackage;

    voice.enable = true;
    service.enable = true;

    desktop = {
      enable = true;
      stt.endpoint = "http://127.0.0.1:10301/inference";
    };
  };
}
