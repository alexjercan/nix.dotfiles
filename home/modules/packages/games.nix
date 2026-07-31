{pkgs, ...}: {
  home.packages = with pkgs; [
    prismlauncher
    wesnoth
  ];
}
