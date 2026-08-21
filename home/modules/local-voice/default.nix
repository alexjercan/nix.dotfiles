{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.localVoice;
  whisperEndpoint = "http://${cfg.whisper.host}:${toString cfg.whisper.port}/inference";

  whisperModel = pkgs.fetchurl {
    name = "ggml-large-v3-turbo-q5_0.bin";
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin";
    hash = "sha256-OUIhcJzVrR9AxG5gMcphvOiJMebgiMGIKUxtWlX/p+I=";
  };
  piperModel = pkgs.fetchurl {
    name = "en_US-lessac-medium.onnx";
    url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx";
    hash = "sha256-Xv4J5pkCGHgnr2RuGm6dJp3udp+Yd9F7FrG0buqvAZ8=";
  };
  piperConfig = pkgs.fetchurl {
    name = "en_US-lessac-medium.onnx.json";
    url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json";
    hash = "sha256-7+GcQXvtBV8taZCCSMa6ZQ+hNbyGiw5quz2hgdq2kKA=";
  };
  piperVoice = pkgs.runCommand "piper-voice-en_US-lessac-medium" {} ''
    mkdir -p "$out/share/piper-voices"
    ln -s ${piperModel} "$out/share/piper-voices/en_US-lessac-medium.onnx"
    ln -s ${piperConfig} "$out/share/piper-voices/en_US-lessac-medium.onnx.json"
  '';

  popupLauncher = pkgs.writeShellApplication {
    name = "scufris-popup-launch";
    runtimeInputs = [
      pkgs.coreutils
      cfg.piper.package
      pkgs.pipewire
      config.programs.pi.coding-agent.finalPackage
    ];
    text = ''
      install -d -m 0700 ${lib.escapeShellArg cfg.scufris.sessionDirectory}
      export PI_STT_CONFIG=${lib.escapeShellArg cfg.sttConfigPath}
      export SCUFRIS_SPEECH=1
      export SCUFRIS_CALM=1
      export SCUFRIS_PIPER_MODEL=${lib.escapeShellArg (toString cfg.piper.model)}
      export SCUFRIS_PIPER_CONFIG=${lib.escapeShellArg (toString cfg.piper.config)}
      exec ${lib.getExe cfg.scufris.package} \
        --session-dir ${lib.escapeShellArg cfg.scufris.sessionDirectory} \
        --continue
    '';
  };

  kittyLauncher = pkgs.writeShellApplication {
    name = "scufris-popup-kitty";
    runtimeInputs = [pkgs.kitty];
    text = ''
      exec kitty \
        --class ${lib.escapeShellArg cfg.scufris.windowClass} \
        --name ${lib.escapeShellArg cfg.scufris.windowInstance} \
        --title ${lib.escapeShellArg cfg.scufris.windowTitle} \
        ${lib.getExe popupLauncher}
    '';
  };

  ownerCriteria = ''class="^${cfg.scufris.windowClass}$" instance="^${cfg.scufris.windowInstance}$"'';
  markedCriteria = ''${ownerCriteria} con_mark="^${cfg.scufris.windowMark}$"'';
  ownerQuery = pkgs.writeShellApplication {
    name = "scufris-popup-owned-window";
    runtimeInputs = [pkgs.jq];
    text = ''
      jq -e \
        --arg class ${lib.escapeShellArg cfg.scufris.windowClass} \
        --arg instance ${lib.escapeShellArg cfg.scufris.windowInstance} \
        --arg mark ${lib.escapeShellArg cfg.scufris.windowMark} \
        '.. | objects | select(.window_properties?.class == $class and .window_properties?.instance == $instance and ((.marks // []) | index($mark) != null))' \
        >/dev/null
    '';
  };
  toggle = pkgs.writeShellApplication {
    name = "scufris-popup-toggle";
    runtimeInputs = [pkgs.i3 pkgs.systemd ownerQuery];
    text = ''
      readonly criteria=${lib.escapeShellArg "[${markedCriteria}]"}
      window_exists() {
        i3-msg -t get_tree | ${lib.getExe ownerQuery}
      }

      if window_exists; then
        exec i3-msg "$criteria scratchpad show"
      fi

      systemctl --user start scufris-popup.service
      for _ in $(seq 1 50); do
        if window_exists; then
          exec i3-msg "$criteria scratchpad show"
        fi
        sleep 0.1
      done
      echo "Scufris popup did not create its Kitty window" >&2
      exit 1
    '';
  };
in {
  options.services.localVoice = {
    enable = lib.mkEnableOption "local Pi speech and the Scufris voice popup";

    sttConfigPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/pi-voice-stt/config.json";
      description = "Absolute pi-voice-stt configuration path.";
    };

    whisper = {
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

    piper = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.piper-tts;
        defaultText = lib.literalExpression "pkgs.piper-tts";
        description = "Piper text-to-speech package.";
      };
      model = lib.mkOption {
        type = lib.types.path;
        default = piperVoice + "/share/piper-voices/en_US-lessac-medium.onnx";
        description = "Pinned Piper ONNX voice model.";
      };
      config = lib.mkOption {
        type = lib.types.path;
        default = piperVoice + "/share/piper-voices/en_US-lessac-medium.onnx.json";
        description = "Pinned Piper voice configuration adjacent to the model.";
      };
    };

    finalPopupLauncher = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "Rendered Scufris popup launcher.";
    };
    finalKittyLauncher = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "Rendered Scufris Kitty launcher.";
    };
    finalToggle = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "Rendered idempotent i3 popup toggle.";
    };
    finalOwnerQuery = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "Rendered exact popup ownership query.";
    };

    scufris = {
      package = lib.mkOption {
        type = lib.types.package;
        description = "Scufris package used only by the popup launcher.";
      };
      sessionDirectory = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/.local/share/scufris-popup/sessions";
        description = "Dedicated persisted Pi session directory for the popup.";
      };
      windowClass = lib.mkOption {
        type = lib.types.strMatching "[A-Za-z0-9_-]+";
        default = "Scufris";
        description = "Exact popup Kitty class.";
      };
      windowInstance = lib.mkOption {
        type = lib.types.strMatching "[A-Za-z0-9_-]+";
        default = "scufris-popup";
        description = "Exact popup Kitty instance.";
      };
      windowTitle = lib.mkOption {
        type = lib.types.strMatching "[A-Za-z0-9 _-]+";
        default = "Scufris";
        description = "Initial popup Kitty title.";
      };
      windowMark = lib.mkOption {
        type = lib.types.strMatching "[A-Za-z0-9_-]+";
        default = "scufris-popup";
        description = "Exact i3 ownership mark for runtime popup control.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.programs.agents.enable && config.programs.agents.pi.enable && config.programs.agents.pi.voiceStt.enable;
        message = "services.localVoice requires programs.agents.pi.voiceStt.enable";
      }
      {
        assertion = cfg.sttConfigPath == config.home.sessionVariables.PI_STT_CONFIG;
        message = "services.localVoice and pi-voice-stt must use the same config path";
      }
      {
        assertion = (config.programs.agents.pi.voiceStt.settings.provider.endpoint or null) == whisperEndpoint;
        message = "services.localVoice and pi-voice-stt must use the same loopback endpoint";
      }
      {
        assertion = cfg.piper.package.version == "1.4.2";
        message = "services.localVoice requires Piper 1.4.2";
      }
      {
        # Piper 1.4.2 accepts --config but still resolves model.json itself.
        assertion = toString cfg.piper.config == "${toString cfg.piper.model}.json";
        message = "services.localVoice requires the Piper config beside the model as model.json";
      }
    ];

    services.localVoice = {
      finalPopupLauncher = popupLauncher;
      finalKittyLauncher = kittyLauncher;
      finalToggle = toggle;
      finalOwnerQuery = ownerQuery;
    };

    home.packages = [cfg.piper.package toggle];

    systemd.user.services.whisper-server = {
      Unit = {
        Description = "Loopback whisper.cpp speech-to-text server";
        After = ["network.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = lib.escapeShellArgs [
          (lib.getExe' cfg.whisper.package "whisper-server")
          "--model"
          (toString cfg.whisper.model)
          "--host"
          cfg.whisper.host
          "--port"
          (toString cfg.whisper.port)
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

    systemd.user.services.scufris-popup = {
      Unit = {
        Description = "Direct Scufris Kitty voice popup";
        After = ["graphical-session.target" "whisper-server.service"];
        Wants = ["whisper-server.service"];
      };
      Service = {
        Type = "simple";
        ExecStart = lib.getExe kittyLauncher;
        Restart = "no";
        WorkingDirectory = "%h";
      };
    };

    xsession.windowManager.i3.config = {
      startup = [
        {
          command = "systemctl --user start scufris-popup.service";
          notification = false;
        }
      ];
      keybindings."Mod4+s" = "exec --no-startup-id ${lib.getExe toggle}";
    };
    xsession.windowManager.i3.extraConfig = ''
      for_window [${ownerCriteria}] mark --add ${cfg.scufris.windowMark}, floating enable, resize set 1000 720, move position center, move scratchpad
    '';
  };
}
