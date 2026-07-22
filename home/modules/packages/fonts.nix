# Fonts. Iosevka is referenced by name across kitty, i3, dunst and waybar, so it
# is installed explicitly here rather than relying on any one feature module.
{pkgs, ...}: {
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    iosevka
  ];
}
