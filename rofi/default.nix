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
        bad0 = mkLiteral "#181818";
        bad1 = mkLiteral "#D7B650";
        bad2 = mkLiteral "#496519";
        bad3 = mkLiteral "#BCBF30";

        bad4 = mkLiteral "#FFD700";
        bad5 = mkLiteral "#348B4A";
        bad6 = mkLiteral "#678C61";

        bad7 = mkLiteral "#6D683C";
        bad8 = mkLiteral "#404040";
        bad9 = mkLiteral "#816C00";
        bad10 = mkLiteral "#305636";
        bad11 = mkLiteral "#FFD770";

        bad12 = mkLiteral "#4692EA";
        bad13 = mkLiteral "#644A7F";
        bad14 = mkLiteral "#81AD8E";
        bad15 = mkLiteral "#CEB874";

        cursor = mkLiteral "#404040";
        background = mkLiteral "#161616";
        foreground = mkLiteral "#F1EFF0";
        bg-selected = mkLiteral "#292929";
        fg-selected = mkLiteral "#404040";

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
        text-color = mkLiteral "@bad4";
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
        background-color = mkLiteral "@bad4";
      };

      "#element-text" = {
        background-color = mkLiteral "transparent";
      };
      "#element-text.selected" = {
        text-color = mkLiteral "@bad0";
      };

      "#element-icon" = {
        background-color = mkLiteral "transparent";
        size = mkLiteral "0.75em";
      };
    };
  };
}
