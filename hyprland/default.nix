{pkgs, ...}: {
  home.packages = with pkgs; [
    hyprcursor
    hypridle
    hyprlock
    hyprpaper
    hyprpicker
    hyprpolkitagent
    hyprsunset
    pyprland
    wl-clipboard
    wlogout
  ];

  programs.wlogout = {
    enable = true;

    layout = [
      {
        label = "lock";
        action = "hyprlock";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "Hibernate";
        keybind = "h";
      }
      {
        label = "logout";
        action = "loginctl terminate-user $USER";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
    ];

    # FIXME: currently the images are not working
    # style = ./wlogout-style.css;
  };

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      "$mod" = "SUPER";

      env = [
        "XCURSOR_THEME,Adwaita"
        "XCURSOR_SIZE,24"
      ];

      general = {
        gaps_in = 4;
        gaps_out = 4;
        border_size = 2;
        "col.active_border" = "rgb(e3e3e3)";
        no_border_on_floating = true;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        enable_swallow = true;
        swallow_regex = "^(kitty)$";
      };

      decoration = {
        rounding = 5;

        active_opacity = 1.0;
        inactive_opacity = 1.0;
        fullscreen_opacity = 1.0;

        blur = {
          enabled = true;
          size = 2;
          passes = 2;
          new_optimizations = true;
        };

        shadow = {
        };
      };

      animations = {
        enabled = true;

        bezier = [
          "myBezier, 0.05, 0.9, 0.1, 1.05"
        ];

        animation = [
          "windows, 1, 2, myBezier"
          "windowsOut, 1, 2, default, popin 80%"
          "border, 1, 3, default"
          "fade, 1, 2, default"
          "workspaces, 1, 1, default"
        ];
      };

      exec-once = [
        "hyprpaper &"
        "waybar &"
        "nm-applet"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bind =
        [
          "$mod, RETURN, exec, kitty"
          "$mod SHIFT, C, killactive, "

          "$mod, R, exec, rofi -modi drun -show drun"
          "$mod, PERIOD, exec, rofi -mode emoji -show emoji -emoji-mode copy"

          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, K, movefocus, u"
          "$mod, J, movefocus, d"

          "$mod SHIFT, H, movewindow, l"
          "$mod SHIFT, L, movewindow, r"
          "$mod SHIFT, K, movewindow, u"
          "$mod SHIFT, J, movewindow, d"

          "$mod, Space, togglefloating, "
          "$mod, S, togglesplit, "

          "$mod, B, exec, firefox"
          "$mod, E, exec, pcmanfm"

          "$mod SHIFT, X, exec, hyprpicker -a -n"
          "$mod, Escape, exec, hyprlock"
          "$mod SHIFT, Escape, exit"
          "CTRL ALT, Delete, exec, wlogout --protocol layer-shell -b 5 -T 400 -B 400"

          "$mod SHIFT, W, exec, bash -c \"kill -SIGUSR2 $(pidof waybar)\""
          "$mod,       W, exec, bash -c \"kill -SIGUSR1 $(pidof waybar)\""
        ]
        ++ (
          builtins.concatLists (builtins.genList (
              i: let
                ws = i + 1;
                key = toString i;
              in [
                "$mod, code:1${key}, workspace, ${toString ws}"
                "$mod SHIFT, code:1${key}, movetoworkspace, ${toString ws}"
              ]
            )
            10)
        );
    };
  };

  programs.waybar = {
    enable = true;
  };

  home.file.".local/share/wlogout-icons" = {
    source = ./wlogout-icons;
    recursive = true;
  };

  home.file.".local/share/wallpapers" = {
    source = ./wallpapers;
    recursive = true;
  };

  xdg.configFile."waybar/config.jsonc".source = ./waybar-config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar-style.css;
  xdg.configFile."hypr/hyprpaper.conf".source = ./hyprpaper.conf;
}
