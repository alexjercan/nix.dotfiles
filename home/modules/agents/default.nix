{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./module.nix
    inputs.ai-tools-api.homeModules.default
  ];

  services.ai-tools-api = {
    enable = true;
    host = "0.0.0.0";
    llamaPackage = pkgs.llama-cpp.override {cudaSupport = true;};
  };

  programs.agents = {
    enable = true;
    agentsFile = toString ./AGENTS.md;

    # A global tool gets a global skill. Every project used to carry its own
    # copy and they drifted. A skill that is tuned per project, such as review
    # or pair, still belongs to that project.
    skills = {
      sprout = toString ../scripts/skills/sprout;
      tatr = inputs.tatr.skills.tatr;
    };

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
