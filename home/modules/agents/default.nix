{
  inputs,
  pkgs,
  ...
}: let
  # Every provider below reaches the same local llama-cpp router; only the
  # model catalogue differs, so Pi names the model family instead of lumping
  # unrelated families under one provider.
  llamaCpp = {
    baseUrl = "http://localhost:10302/v1";
    api = "openai-completions";
    apiKey = "local";
    compat = {
      supportsDeveloperRole = false;
      supportsReasoningEffort = false;
      maxTokensField = "max_tokens";
      thinkingTokenBudgetField = "thinking_budget_tokens";
    };
  };
in {
  imports = [./module.nix];

  services = {
    llama-cpp = {
      enable = true;
      host = "0.0.0.0";
      port = 10302;
      package = pkgs.llama-cpp.override {cudaSupport = true;};
      # 32K leaves KV-cache headroom on the 8 GiB GPU. The module default of
      # 128K forces this host to offload cache to CPU RAM.
      contextSize = 32768;
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
        pi-ask-user.enable = true;
        pi-subagents = {
          enable = true;
        };
        pi-observational-memory = {
          enable = true;
          config = {
            observeAfterTokens = 10000;
            reflectAfterTokens = 20000;
            compactAfterTokens = 81000;
            compactAfterTokensMode = "calibrated";
            compactAfterTokensRatio = 0.68;
            observationsPoolMaxTokens = 20000;
            observationsPoolTargetTokens = 10000;
            agentMaxTurns = 16;
            model = {
              provider = "openai-codex";
              id = "gpt-6-luna";
              thinking = "medium";
            };
            showWorkerNotifications = true;
            passive = false;
            debugLog = false;
          };
        };
        plannotator.enable = true;
        tasks.enable = true;

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

      # Points at the local llama-cpp server declared above. The router serves
      # every model under one --ctx-size, so each entry advertises the service
      # context rather than the model maximum.
      models = {
        providers = {
          gemma =
            llamaCpp
            // {
              models = [
                {
                  id = "gemma-4-12B-it-qat";
                  name = "Gemma 4 12B IT QAT";
                  reasoning = true;
                  input = ["text"];
                  contextWindow = 32768;
                  maxTokens = 16384;
                }
                {
                  id = "gemma-4-26B-A4B-it";
                  name = "Gemma 4 26B A4B";
                  reasoning = true;
                  input = ["text"];
                  contextWindow = 32768;
                  maxTokens = 16384;
                }
              ];
            };
          qwen =
            llamaCpp
            // {
              models = [
                {
                  id = "Qwen3.5-9B";
                  name = "Qwen3.5 9B";
                  reasoning = true;
                  input = ["text"];
                  contextWindow = 32768;
                  maxTokens = 16384;
                }
              ];
            };
        };
      };
    };
  };
}
