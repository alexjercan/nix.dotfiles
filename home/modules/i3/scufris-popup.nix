{
  config,
  lib,
  pkgs,
  ...
}: let
  i3Cfg = config.xsession.windowManager.i3;
  cfg = i3Cfg.scufrisPopup;
  scufrisCfg = config.programs.scufris;
  popupCfg = scufrisCfg.voice.popup;
  ownerCriteria = ''class="^${popupCfg.class}$" instance="^${popupCfg.instance}$"'';
  markedCriteria = ''${ownerCriteria} con_mark="^${cfg.mark}$"'';
  ownerQuery = pkgs.writeShellApplication {
    name = "scufris-popup-owned-window";
    runtimeInputs = [pkgs.jq];
    text = ''
      jq -e \
        --arg class ${lib.escapeShellArg popupCfg.class} \
        --arg instance ${lib.escapeShellArg popupCfg.instance} \
        --arg mark ${lib.escapeShellArg cfg.mark} \
        '.. | objects | select(.window_properties?.class == $class and .window_properties?.instance == $instance and ((.marks // []) | index($mark) != null))' \
        >/dev/null
    '';
  };
  toggle = pkgs.writeShellApplication {
    name = "scufris-popup-toggle";
    runtimeInputs = [pkgs.coreutils pkgs.i3 pkgs.systemd ownerQuery];
    text = ''
      readonly criteria=${lib.escapeShellArg "[${markedCriteria}]"}
      window_exists() {
        i3-msg -t get_tree | ${lib.getExe ownerQuery}
      }

      if window_exists; then
        exec i3-msg "$criteria scratchpad show"
      fi

      systemctl --user start ${lib.escapeShellArg "${popupCfg.serviceName}.service"}
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
  options.xsession.windowManager.i3.scufrisPopup = {
    enable = lib.mkEnableOption "the Scufris popup i3 consumer";

    mark = lib.mkOption {
      type = lib.types.strMatching "[A-Za-z0-9_-]+";
      default = "scufris-popup";
      description = "Exact i3 ownership mark for the Scufris popup.";
    };

    finalOwnerQuery = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "Rendered exact popup ownership query.";
    };

    finalToggle = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "Rendered idempotent popup toggle.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = i3Cfg.enable;
        message = "xsession.windowManager.i3.scufrisPopup.enable requires xsession.windowManager.i3.enable";
      }
      {
        assertion = scufrisCfg.enable && scufrisCfg.voice.enable && popupCfg.enable;
        message = "xsession.windowManager.i3.scufrisPopup.enable requires programs.scufris.voice.popup.enable";
      }
    ];

    xsession.windowManager.i3 = {
      scufrisPopup = {
        finalOwnerQuery = ownerQuery;
        finalToggle = toggle;
      };
      config = {
        startup = [
          {
            command = "systemctl --user start ${popupCfg.serviceName}.service";
            notification = false;
          }
        ];
        keybindings."${i3Cfg.config.modifier}+s" = "exec --no-startup-id ${lib.getExe toggle}";
      };
      extraConfig = ''
        for_window [${ownerCriteria}] mark --add ${cfg.mark}, floating enable, resize set 1000 720, move position center, move scratchpad
      '';
    };
  };
}
