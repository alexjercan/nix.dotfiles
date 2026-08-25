{pkgs, ...}: {
  imports = [
    ./module.nix
  ];

  programs.agents = {
    enable = true;
    agentsFile = toString ./AGENTS.md;

    agentBrowser.enable = true;
    claudeCode.enable = true;
    codex.enable = true;
    opencode.enable = true;

    pi = {
      enable = true;

      themes.gruber-darker.enable = true;
      extensions = {
        plannotator.enable = true;
        quick-review.enable = true;

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

      settings = {
        theme = "gruber-darker";
      };
    };
  };
}
