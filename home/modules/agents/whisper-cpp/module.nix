{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.whisper-cpp;
  model = pkgs.fetchurl {
    name = "ggml-large-v3-turbo-q5_0.bin";
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin";
    hash = "sha256-OUIhcJzVrR9AxG5gMcphvOiJMebgiMGIKUxtWlX/p+I=";
  };
in {
  options.services.whisper-cpp = {
    enable = lib.mkEnableOption "whisper.cpp HTTP server";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.whisper-cpp-vulkan;
      defaultText = lib.literalExpression "pkgs.whisper-cpp-vulkan";
      description = "Package that provides whisper-server.";
    };

    model = lib.mkOption {
      type = lib.types.package;
      default = model;
      description = "Whisper GGML model.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "HTTP bind address.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 10301;
      description = "HTTP port.";
    };

    language = lib.mkOption {
      type = lib.types.str;
      default = "auto";
      description = "Default transcription language.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra arguments passed to whisper-server.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.whisper-cpp = {
      Unit = {
        Description = "whisper.cpp HTTP server";
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };
      Service = {
        Type = "simple";
        ExecStart = lib.escapeShellArgs (
          [
            (lib.getExe' cfg.package "whisper-server")
            "--model"
            (toString cfg.model)
            "--host"
            cfg.host
            "--port"
            (toString cfg.port)
            "--inference-path"
            "/inference"
            "--language"
            cfg.language
          ]
          ++ cfg.extraArgs
        );
        Restart = "on-failure";
        RestartSec = 5;
        RuntimeDirectory = "whisper-cpp";
        WorkingDirectory = "%t/whisper-cpp";
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
