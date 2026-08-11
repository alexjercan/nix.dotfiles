{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.agents.homeModules.default];

  programs.agents = {
    enable = true;
    agentsFile = ./AGENTS.md;

    skills = {
      compound = ./skills/compound;
      review = ./skills/review;
      sprout = ./skills/sprout;
      tatr = inputs.tatr.skills.tatr;
      understand = ./skills/understand;
      work = ./skills/work;
      today = inputs.today.skills.today;
    };

    agentBrowser.enable = true;
    claudeCode.enable = true;
    codex.enable = true;
    knowledge.enable = true;
    opencode.enable = true;

    pi = {
      extensions = [inputs.agents.extensions.${pkgs.system}.plannotator];
      themes = [inputs.agents.themes.gruber-darker];
    };
  };

  programs.pi.coding-agent.settings.theme = "gruber-darker";
}
