# i3 side of the Scufris voice popup: start its unit with the session, toggle it
# from the scratchpad, and place the window. Applies only when i3 and the popup
# are both on, so a Hyprland session can import the module unharmed.
{
  config,
  lib,
  pkgs,
  ...
}: let
  i3 = config.xsession.windowManager.i3;
  scufris = config.programs.scufris;
  popup = scufris.voice.popup;

  # Mirrors the gate upstream puts on the popup unit, so the keybinding never
  # points at a service that was not generated.
  popupEnabled = scufris.enable && scufris.voice.enable && popup.enable;

  # The popup title changes at runtime, so ownership is class plus instance plus
  # our own mark and never the title.
  mark = "scufris-popup";
  ownerCriteria = ''class="^${popup.class}$" instance="^${popup.instance}$"'';
  markedCriteria = ''${ownerCriteria} con_mark="^${mark}$"'';

  ownerQuery = pkgs.writeShellApplication {
    name = "scufris-popup-owned-window";
    runtimeInputs = [pkgs.jq];
    text = ''
      jq -e \
        --arg class ${lib.escapeShellArg popup.class} \
        --arg instance ${lib.escapeShellArg popup.instance} \
        --arg mark ${lib.escapeShellArg mark} \
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

      systemctl --user start ${lib.escapeShellArg "${popup.serviceName}.service"}
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
  config = lib.mkIf (i3.enable && popupEnabled) {
    xsession.windowManager.i3 = {
      config = {
        startup = [
          {
            command = "systemctl --user start ${popup.serviceName}.service";
            notification = false;
          }
        ];
        keybindings."${i3.config.modifier}+s" = "exec --no-startup-id ${lib.getExe toggle}";
      };
      extraConfig = ''
        for_window [${ownerCriteria}] mark --add ${mark}, floating enable, resize set 1000 720, move position center, move scratchpad
      '';
    };
  };
}
