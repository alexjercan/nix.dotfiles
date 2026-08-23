{
  inputs,
  pkgs,
  ...
}: let
  sourceRoot = inputs.self + "/home/modules/agents";
  piExtensions = import ./pi-extensions {inherit pkgs sourceRoot;};
in {
  imports = [
    (import ./module.nix {
      piModule = inputs.pi.homeModules.default;
      inherit sourceRoot;
    })
  ];

  programs.agents = {
    enable = true;
    agentsFile = sourceRoot + "/AGENTS.md";

    agentBrowser.enable = true;
    claudeCode.enable = true;
    codex.enable = true;
    opencode.enable = true;
    plannotator.enable = true;

    pi = {
      extensions = [piExtensions.plannotator];
      themes = [(sourceRoot + "/themes/gruber-darker.json")];
    };
  };

  programs.pi.coding-agent.settings.theme = "gruber-darker";
}
