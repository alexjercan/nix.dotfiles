{config, ...}: {
  programs.scufris = {
    enable = true;

    service = {
      enable = true;
      agent.piPackage = config.programs.agents.pi.finalPackage;
    };

    desktop = {
      enable = true;
      speech.enable = true;
      aiToolsApi = {
        manage = false;
        baseUrl = "http://127.0.0.1:10300";
      };
    };
  };
}
