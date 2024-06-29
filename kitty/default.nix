{pkgs, ...}: {
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

      background = "#181818";
      foreground = "#E4E4E4";
      cursor = "#FFDD33";
      selection_background = "#FFFFFF";
      color0 = "#181818";
      color8 = "#52494E";
      color1 = "#F43841";
      color9 = "#FF4F58";
      color2 = "#73D936";
      color10 = "#73D936";
      color3 = "#FFDD33";
      color11 = "#FFDD33";
      color4 = "#96A6C8";
      color12 = "#52494E";
      color5 = "#9E95C7";
      color13 = "#9E95C7";
      color6 = "#95A99F";
      color14 = "#95A99F";
      color7 = "#E4E4E4";
      color15 = "#F5F5F5";
      selection_foreground = "#52494E";
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
