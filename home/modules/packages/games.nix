# Games and game launchers.
{pkgs, ...}: {
  home.packages = with pkgs; [
    prismlauncher
    wesnoth
  ];
}
