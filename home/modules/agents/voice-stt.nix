{piExtensions}: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.agents;
  voiceCfg = cfg.pi.voiceStt;
  whisperCfg = voiceCfg.localWhisper;
  json = pkgs.formats.json {};
  whisperModel = pkgs.fetchurl {
    name = "ggml-large-v3-turbo-q5_0.bin";
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin";
    hash = "sha256-OUIhcJzVrR9AxG5gMcphvOiJMebgiMGIKUxtWlX/p+I=";
  };
  managedProvider = {
    type = "openai-compatible";
    endpoint = "http://${whisperCfg.host}:${toString whisperCfg.port}/inference";
    model = "whisper-1";
    language = "auto";
    apiKeyEnv = "";
  };
  finalSettings =
    voiceCfg.settings
    // lib.optionalAttrs whisperCfg.enable {provider = managedProvider;};
in {
  options.programs.agents.pi.voiceStt = {
    enable = lib.mkEnableOption "speech-to-text in Pi";

    extension = lib.mkOption {
      type = lib.types.package;
      default = piExtensions.voice-stt;
      defaultText = lib.literalExpression "piExtensions.voice-stt";
      description = "Pinned pi-voice-stt extension package.";
    };

    ffmpegPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ffmpeg;
      defaultText = lib.literalExpression "pkgs.ffmpeg";
      description = "FFmpeg package used for microphone capture.";
    };

    settings = lib.mkOption {
      inherit (json) type;
      default = {};
      description = "pi-voice-stt JSON configuration excluding a managed local Whisper provider.";
    };

    localWhisper = {
      enable = lib.mkEnableOption "a managed loopback whisper.cpp provider";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.whisper-cpp-vulkan;
        defaultText = lib.literalExpression "pkgs.whisper-cpp-vulkan";
        description = "whisper.cpp package that provides whisper-server.";
      };

      model = lib.mkOption {
        type = lib.types.package;
        default = whisperModel;
        description = "Pinned whisper.cpp GGML model.";
      };

      host = lib.mkOption {
        type = lib.types.enum ["127.0.0.1"];
        default = "127.0.0.1";
        description = "Loopback address for whisper-server.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 10301;
        description = "Loopback port for whisper-server.";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = !voiceCfg.enable || cfg.pi.enable;
          message = "programs.agents.pi.voiceStt.enable requires programs.agents.pi.enable";
        }
        {
          assertion = !whisperCfg.enable || voiceCfg.enable;
          message = "programs.agents.pi.voiceStt.localWhisper.enable requires programs.agents.pi.voiceStt.enable";
        }
        {
          assertion = !whisperCfg.enable || !(voiceCfg.settings ? provider);
          message = "programs.agents.pi.voiceStt.localWhisper conflicts with programs.agents.pi.voiceStt.settings.provider";
        }
      ];
    }

    (lib.mkIf (cfg.pi.enable && voiceCfg.enable) {
      home.packages = [voiceCfg.ffmpegPackage];
      home.file.".pi/agent/stt.json".source = json.generate "pi-voice-stt-config.json" finalSettings;
    })

    (lib.mkIf (cfg.pi.enable && voiceCfg.enable && whisperCfg.enable) {
      systemd.user.services.whisper-server = {
        Unit = {
          Description = "Loopback whisper.cpp speech-to-text server";
          After = ["network.target"];
        };
        Service = {
          Type = "simple";
          ExecStart = lib.escapeShellArgs [
            (lib.getExe' whisperCfg.package "whisper-server")
            "--model"
            (toString whisperCfg.model)
            "--host"
            whisperCfg.host
            "--port"
            (toString whisperCfg.port)
            "--inference-path"
            "/inference"
            "--language"
            "auto"
          ];
          Restart = "no";
          RuntimeDirectory = "whisper-server";
          WorkingDirectory = "%t/whisper-server";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
        };
        Install.WantedBy = ["default.target"];
      };
    })
  ]);
}
