{config, ...}: {
  programs.scufris = {
    enable = true;

    agent.piPackage = config.programs.agents.pi.finalPackage;
    aiToolsApi = {
      enable = false;
      baseUrl = "http://127.0.0.1:10300";
    };

    service = {
      enable = true;
      remoteSurface = {
        enable = true;
        port = 10440;
        tokenFile = "${config.xdg.dataHome}/scufris/credentials/ios/surface-token";
      };
    };

    desktop = {
      enable = true;
      speech.enable = true;
    };
  };
}
