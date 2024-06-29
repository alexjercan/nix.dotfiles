{
  pkgs,
  ...
}: {
  programs.kitty = {
    enable = true;

    settings = {
        cursor_shape = "block";
        cursor_blink_interval = "0.5";
        cursor_stop_blinking_after = "15.0";
        enable_audio_bell = false;
        hide_window_decorations = true;
        background_opacity = "1.0";
        allow_remote_control = true;

        background = "#161616";
        foreground = "#F1EFF0";
        cursor = "#AAAAAA";
        selection_background = "#292929";
        color0 = "#181818";
        color8 = "#404040";
        color1 = "#D7B650";
        color9 = "#816C00";
        color2 = "#496519";
        color10 = "#305636";
        color3 = "#BCBF30";
        color11 = "#FFD770";
        color4 = "#FFD700";
        color12 = "#4692EA";
        color5 = "#348B4A";
        color13 = "#644A7F";
        color6 = "#678C61";
        color14 = "#81AD8E";
        color7 = "#6D683C";
        color15 = "#CEB874";
        selection_foreground = "#404040";
    };

    keybindings = {
        "ctrl+f" = "launch --type=overlay-main sesh";
    };

    font = {
        package = pkgs.iosevka;
        name = "Iosevka";
        size = 14;
    };
  };
}