{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.kev;
  # Kev uses a custom pointer head, so its Python server must run beside llama.cpp.
  source = pkgs.fetchzip {
    url = "https://github.com/jaredpalmer/kev/archive/5e42a7a03f28134853dd3ff77461457e921e5ec1.tar.gz";
    hash = "sha256-ZATNgY6Yq8NPNeQ08BceBnHxU4W3MaMMxiKgAl7vofg=";
  };
  start = pkgs.writeShellScript "kev-serve" ''
    set -eu
    export UV_PROJECT_ENVIRONMENT="$1/venv"
    export UV_CACHE_DIR="$2/uv"
    export HF_HOME="$2/huggingface"
    # PyPI's torch wheel needs the C++ runtime and the NixOS NVIDIA driver.
    export LD_LIBRARY_PATH=${lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib]}:/run/opengl-driver/lib
    export UV_PYTHON_DOWNLOADS=never
    # Keep Kev's source in the Nix store; setuptools cannot build an editable
    # install there because it writes egg-info into the source directory.
    export PYTHONPATH=${source}
    ${lib.getExe pkgs.uv} sync --project ${source} --frozen --no-dev --no-install-project --extra serve --python ${lib.getExe pkgs.python313}
    exec ${lib.getExe pkgs.uv} run --project ${source} --no-sync python -m kev.serve \
      --run ${lib.escapeShellArg cfg.model} --host ${lib.escapeShellArg cfg.host} --port ${toString cfg.port}
  '';
in {
  options.services.kev = {
    enable = lib.mkEnableOption "Kev decision-model HTTP server";

    model = lib.mkOption {
      type = lib.types.str;
      default = "jaredpalmer/kev-0.8b@v1.0";
      description = "Hugging Face Kev checkpoint and revision.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "HTTP bind address.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 10304;
      description = "HTTP port.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.kev = {
      Unit = {
        Description = "Kev decision-model HTTP server";
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };
      Service = {
        Type = "simple";
        ExecStart = lib.escapeShellArgs [(toString start) "%S/kev" "%C/kev"];
        Restart = "on-failure";
        RestartSec = 5;
        StateDirectory = "kev";
        CacheDirectory = "kev";
        RuntimeDirectory = "kev";
        WorkingDirectory = "%t/kev";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        UMask = "0077";
        TimeoutStopSec = 10;
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
