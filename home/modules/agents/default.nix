{
  inputs,
  pkgs,
  ...
}: let
  sourceRoot = inputs.self + "/home/modules/agents";
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

    pi = {
      themes.gruber-darker.enable = true;

      extensions = {
        plannotator.enable = true;

        voice-stt = {
          enable = true;
          localWhisper.enable = true;
          settings = {
            keybind = "ctrl+r";
            capture = {
              type = "ffmpeg";
              ffmpegPath = "${pkgs.ffmpeg}/bin/ffmpeg";
              inputFormat = "pulse";
              input = "default";
              sampleRate = 16000;
              channels = 1;
            };
            cleanup.enabled = false;
          };
        };
      };
    };
  };

  programs.pi.coding-agent.settings.theme = "gruber-darker";
}
