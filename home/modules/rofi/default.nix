{
  pkgs,
  config,
  ...
}: {
  programs.rofi = {
    enable = true;
    plugins = [pkgs.rofi-emoji];
    font = "Iosevka 16";
    terminal = "${pkgs.kitty}/bin/kitty";
    cycle = true;
    extraConfig = {
      modi = "window,drun,run,emoji,ssh";
      show-icons = true;
    };
    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      /*
       ******************************************************************************
      * ROFI ONELINE THEME USING THE BREAKING BAD COLOR PALETTE
      * User                     : alexjercan
      * Theme Repo               : https://github.com/alexjercan/hyprland.dotfiles
      * Breaking Bad Theme Repo  : https://github.com/i3d/vim-jimbothemes
      ******************************************************************************
      */

      "*" = {
        color0 = mkLiteral "#181818";
        color1 = mkLiteral "#F43841";
        color2 = mkLiteral "#73D936";
        color3 = mkLiteral "#FFDD33";

        color4 = mkLiteral "#96A6C8";
        color5 = mkLiteral "#9E95C7";
        color6 = mkLiteral "#95A99F";

        color7 = mkLiteral "#E4E4E4";
        color8 = mkLiteral "#52494E";
        color9 = mkLiteral "#FF4F58";
        color10 = mkLiteral "#73D936";
        color11 = mkLiteral "#FFDD33";

        color12 = mkLiteral "#52494E";
        color13 = mkLiteral "#9E95C7";
        color14 = mkLiteral "#95A99F";
        color15 = mkLiteral "#F5F5F5";

        cursor = mkLiteral "#FFDD33";
        background = mkLiteral "#181818";
        foreground = mkLiteral "#E4E4E4";
        bg-selected = mkLiteral "#FFFFFF";
        fg-selected = mkLiteral "#52494E";

        text-color = mkLiteral "@foreground";
        background-color = mkLiteral "@background";

        width = mkLiteral "30em";
        margin = mkLiteral "0px";
        padding = mkLiteral "0px";
        spacing = mkLiteral "2px";
      };

      "#window" = {
        location = mkLiteral "center";
        anchor = mkLiteral "center";
        height = mkLiteral "60%";
        border = mkLiteral "0px";
        margin = mkLiteral "0px";
        padding = mkLiteral "0px";
      };

      "#inputbar" = {
        padding = mkLiteral "8px 12px";
        spacing = mkLiteral "12px";
        children = map mkLiteral ["prompt" "entry"];
      };

      "#prompt" = {
        background-color = mkLiteral "transparent";
      };

      "#entry" = {
        background-color = mkLiteral "transparent";
      };

      "#listview" = {
        background-color = mkLiteral "transparent";
      };

      "#prompt" = {
        text-color = mkLiteral "@color4";
      };

      "#listview" = {
        lines = mkLiteral "8";
        columns = mkLiteral "1";

        fixed-height = mkLiteral "false";
      };

      "#element" = {
        background-color = mkLiteral "transparent";
        padding = mkLiteral "8px";
        spacing = mkLiteral "8px";
      };
      "#element.selected" = {
        background-color = mkLiteral "@color4";
      };

      "#element-text" = {
        background-color = mkLiteral "transparent";
      };
      "#element-text.selected" = {
        text-color = mkLiteral "@color0";
      };

      "#element-icon" = {
        background-color = mkLiteral "transparent";
        size = mkLiteral "0.75em";
      };
    };
  };
}
