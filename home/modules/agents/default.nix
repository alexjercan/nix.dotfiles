{
  inputs,
  pkgs,
  ...
}: {
  imports = [./module.nix];

  services = {
    llama-cpp = {
      enable = true;
      host = "0.0.0.0";
      port = 10302;
      package = pkgs.llama-cpp.override {cudaSupport = true;};
    };
    piper-tts-api = {
      enable = true;
      host = "0.0.0.0";
      port = 10303;
    };
    whisper-cpp = {
      enable = true;
      host = "0.0.0.0";
      port = 10301;
    };
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
        pi-subagents = {
          enable = true;
        };
        pi-observational-memory.enable = true;
        plannotator.enable = true;

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
              endpoint = "http://127.0.0.1:10301/inference";
              model = "whisper-1";
              language = "auto";
              apiKeyEnv = "";
            };
          };
        };
      };

      settings.theme = "gruber-darker";

      # Points at the local llama-cpp server declared above.
      models = {
        providers.gemma = {
          baseUrl = "http://localhost:10302/v1";
          api = "openai-completions";
          apiKey = "local";
          compat = {
            supportsDeveloperRole = false;
            supportsReasoningEffort = false;
            maxTokensField = "max_tokens";
            thinkingTokenBudgetField = "thinking_budget_tokens";
          };
          models = [
            {
              id = "gemma-4-26B-A4B-it";
              name = "Gemma 4 26B A4B";
              reasoning = true;
              input = ["text"];
              contextWindow = 128000;
              maxTokens = 16384;
            }
          ];
        };
      };
    };
  };
}
