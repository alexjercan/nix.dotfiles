{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./module.nix
    inputs.ai-tools-api.homeModules.default
  ];

  services.ai-tools-api.enable = true;

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
            provider = {
              type = "openai-compatible";
              endpoint = "http://127.0.0.1:10300/v1/audio/transcriptions";
              model = "whisper-1";
              language = "auto";
              apiKeyEnv = "";
            };
          };
        };
      };

      settings = {
        theme = "gruber-darker";
      };
    };
  };
}
