{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.llama-cpp;
  models = import ./models.nix {inherit pkgs;};
in {
  options.services.llama-cpp = {
    enable = lib.mkEnableOption "llama.cpp HTTP server";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llama-cpp-vulkan;
      defaultText = lib.literalExpression "pkgs.llama-cpp-vulkan";
      description = "Package that provides llama-server.";
    };

    modelsPreset = lib.mkOption {
      type = lib.types.package;
      default = models.preset;
      description = "llama.cpp model router preset.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "HTTP bind address.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 10302;
      description = "HTTP port.";
    };

    contextSize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 128000;
      description = "Maximum model context size.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra arguments passed to llama-server.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.llama-cpp = {
      Unit = {
        Description = "llama.cpp HTTP server";
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };
      Service = {
        Type = "simple";
        ExecStart = lib.escapeShellArgs (
          [
            (lib.getExe' cfg.package "llama-server")
            "--models-preset"
            (toString cfg.modelsPreset)
            "--host"
            cfg.host
            "--port"
            (toString cfg.port)
            "--ctx-size"
            (toString cfg.contextSize)
          ]
          ++ cfg.extraArgs
        );
        Restart = "on-failure";
        RestartSec = 5;
        RuntimeDirectory = "llama-cpp";
        WorkingDirectory = "%t/llama-cpp";
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
