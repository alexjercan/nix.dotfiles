{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.piper-tts-api;
  defaultPackage = pkgs.piper-tts.override {
    withTrain = false;
    withHTTP = false;
    withAlignment = false;
  };
  defaultModel = pkgs.fetchurl {
    name = "en_US-lessac-medium.onnx";
    url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx";
    hash = "sha256-Xv4J5pkCGHgnr2RuGm6dJp3udp+Yd9F7FrG0buqvAZ8=";
  };
  defaultConfig = pkgs.fetchurl {
    name = "en_US-lessac-medium.onnx.json";
    url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json";
    hash = "sha256-7+GcQXvtBV8taZCCSMa6ZQ+hNbyGiw5quz2hgdq2kKA=";
  };
  voice = pkgs.runCommand "piper-tts-voice" {} ''
    mkdir -p "$out"
    ln -s ${cfg.model} "$out/en_US-lessac-medium.onnx"
    ln -s ${cfg.modelConfig} "$out/en_US-lessac-medium.onnx.json"
  '';
in {
  options.services.piper-tts-api = {
    enable = lib.mkEnableOption "Piper text-to-speech HTTP API";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      description = "Package that provides Piper.";
    };

    model = lib.mkOption {
      type = lib.types.package;
      default = defaultModel;
      description = "Piper ONNX voice model.";
    };

    modelConfig = lib.mkOption {
      type = lib.types.package;
      default = defaultConfig;
      description = "Piper voice model configuration.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "HTTP bind address.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 10303;
      description = "HTTP port.";
    };

    maxTextBytes = lib.mkOption {
      type = lib.types.ints.between 1 65536;
      default = 4096;
      description = "Maximum UTF-8 input size.";
    };

    timeout = lib.mkOption {
      type = lib.types.ints.between 1 600;
      default = 60;
      description = "Piper timeout in seconds.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.piper-tts-api = {
      Unit = {
        Description = "Piper text-to-speech HTTP API";
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };
      Service = {
        Type = "simple";
        ExecStart = lib.escapeShellArgs [
          (lib.getExe pkgs.python3)
          (toString ./server.py)
          "--host"
          cfg.host
          "--port"
          (toString cfg.port)
          "--piper"
          (lib.getExe cfg.package)
          "--model"
          "${voice}/en_US-lessac-medium.onnx"
          "--config"
          "${voice}/en_US-lessac-medium.onnx.json"
          "--max-text-bytes"
          (toString cfg.maxTextBytes)
          "--timeout"
          (toString cfg.timeout)
        ];
        Restart = "on-failure";
        RestartSec = 5;
        RuntimeDirectory = "piper-tts-api";
        WorkingDirectory = "%t/piper-tts-api";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "tmpfs";
        UMask = "0077";
        TimeoutStopSec = 10;
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
