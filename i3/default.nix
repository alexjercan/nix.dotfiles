{
  pkgs,
  config,
  ...
}: let
  cfg = config.xsession.windowManager.i3;
in {
  xsession.windowManager.i3 = {
    enable = true;

    config = {
      fonts = {
        names = ["Iosevka"];
        size = 8.0;
      };
      modifier = "Mod4";
      terminal = "kitty";
      defaultWorkspace = "workspace number 1";
      window = {
        titlebar = false;
        border = 0;
      };
      floating = {
        titlebar = false;
        border = 0;
      };

      startup = [
        {command = "nm-applet";}
        {command = "dunst";}
        {command = "nitrogen --restore";}
        {command = "xset s off -dpms";}
      ];

      bars = [
        {
          mode = "dock";
          position = "top";
          statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs config-top.toml";
          fonts = {
            names = ["Iosevka"];
            size = 10.0;
          };
          trayOutput = "DP-4";
          trayPadding = 2;
        }
      ];

      keybindings = {
        "${cfg.config.modifier}+Return" = "exec ${cfg.config.terminal}";
        "${cfg.config.modifier}+Shift+c" = "kill";

        "${cfg.config.modifier}+r" = "exec rofi -modi drun -show drun";
        "${cfg.config.modifier}+period" = "exec rofi -mode emoji -show emoji -emoji-mode copy";

        "${cfg.config.modifier}+h" = "focus left";
        "${cfg.config.modifier}+j" = "focus down";
        "${cfg.config.modifier}+k" = "focus up";
        "${cfg.config.modifier}+l" = "focus right";

        "${cfg.config.modifier}+Shift+h" = "move left";
        "${cfg.config.modifier}+Shift+j" = "move down";
        "${cfg.config.modifier}+Shift+k" = "move up";
        "${cfg.config.modifier}+Shift+l" = "move right";

        "${cfg.config.modifier}+z" = "split h";
        "${cfg.config.modifier}+v" = "split v";
        "${cfg.config.modifier}+f" = "fullscreen toggle";
        "${cfg.config.modifier}+Shift+space" = "floating toggle";
        "${cfg.config.modifier}+space" = "focus mode_toggle";
        "${cfg.config.modifier}+a" = "focus parent";

        "${cfg.config.modifier}+1" = "workspace number 1";
        "${cfg.config.modifier}+2" = "workspace number 2";
        "${cfg.config.modifier}+3" = "workspace number 3";
        "${cfg.config.modifier}+4" = "workspace number 4";
        "${cfg.config.modifier}+5" = "workspace number 5";
        "${cfg.config.modifier}+6" = "workspace number 6";
        "${cfg.config.modifier}+7" = "workspace number 7";
        "${cfg.config.modifier}+8" = "workspace number 8";
        "${cfg.config.modifier}+9" = "workspace number 9";
        "${cfg.config.modifier}+0" = "workspace number 10";

        "${cfg.config.modifier}+Shift+1" = "move container to workspace number 1";
        "${cfg.config.modifier}+Shift+2" = "move container to workspace number 2";
        "${cfg.config.modifier}+Shift+3" = "move container to workspace number 3";
        "${cfg.config.modifier}+Shift+4" = "move container to workspace number 4";
        "${cfg.config.modifier}+Shift+5" = "move container to workspace number 5";
        "${cfg.config.modifier}+Shift+6" = "move container to workspace number 6";
        "${cfg.config.modifier}+Shift+7" = "move container to workspace number 7";
        "${cfg.config.modifier}+Shift+8" = "move container to workspace number 8";
        "${cfg.config.modifier}+Shift+9" = "move container to workspace number 9";
        "${cfg.config.modifier}+Shift+0" = "move container to workspace number 10";

        "${cfg.config.modifier}+Shift+w" = "reload";
        "${cfg.config.modifier}+Shift+p" = "restart";
        "${cfg.config.modifier}+Shift+Escape" = "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'";

        "${cfg.config.modifier}+Shift+s" = "exec --no-startup-id scrot -s ~/Pictures/Screenshots/%Y%m%d_%H%M%S.png";
        "${cfg.config.modifier}+s" = "exec --no-startup-id scrot ~/Pictures/Screenshots/%Y%m%d_%H%M%S.png";

        "${cfg.config.modifier}+b" = "exec firefox";
        "${cfg.config.modifier}+e" = "exec pcmanfm";

        "${cfg.config.modifier}+Shift+r" = "mode resize";
        "Ctrl+Mod1+Delete" = "mode system";

        "XF86AudioRaiseVolume" = "exec --no-startup-id pw-volume change +5.0%";
        "XF86AudioLowerVolume" = "exec --no-startup-id pw-volume change -5.0%";
        "XF86AudioMute" = "exec --no-startup-id pw-volume mute toggle";
      };

      modes = {
        resize = {
          "h" = "resize shrink width 10 px or 10 ppt";
          "j" = "resize grow height 10 px or 10 ppt";
          "k" = "resize shrink height 10 px or 10 ppt";
          "l" = "resize grow width 10 px or 10 ppt";

          "Escape" = "mode default";
          "Return" = "mode default";
        };
        system = {
          "l" = "exec --no-startup-id $Locker, mode \"default\"";
          "e" = "exec --no-startup-id i3-msg exit, mode \"default\"";
          "Shift+s" = "exec --no-startup-id $Locker && systemctl suspend, mode \"default\"";
          "h" = "exec --no-startup-id $Locker && systemctl hibernate, mode \"default\"";
          "r" = "exec --no-startup-id systemctl reboot, mode \"default\"";
          "s" = "exec --no-startup-id systemctl poweroff -i, mode \"default\"";

          "Escape" = "mode default";
          "Return" = "mode default";
        };
      };
    };
  };

  programs.i3status-rust = {
    enable = true;

    bars = {
      top = {
        theme = "gruvbox-dark";
        icons = "none";
        blocks = [
          {
            block = "cpu";
            info_cpu = 20;
            warning_cpu = 50;
            critical_cpu = 90;
          }
          {
            block = "disk_space";
            info_type = "available";
            alert_unit = "GB";
            alert = 10.0;
            warning = 15.0;
            format = " $icon $available ";
          }
          {
            block = "memory";
            format = " $icon $mem_total_used_percents.eng(w:2) ";
            format_alt = " $icon_swap $swap_used_percents.eng(w:2) ";
          }
          {
            block = "sound";
            format = " $icon {$volume.eng(w:2) |}";
            click = [
              {
                button = "left";
                cmd = "pwvucontrol";
              }
            ];
          }
          {
            block = "custom";
            interval = 5;
            cycle = [
              " date +'%a %d/%m' "
              " date +'%a %d/%m %H:%M:%S' "
            ];
          }
        ];
      };
    };
  };
}
