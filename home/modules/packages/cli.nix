# Terminal / command-line utilities.
{pkgs, ...}: {
  home.packages = with pkgs; [
    hello

    bat
    btop
    dua
    dust
    fastfetch
    fd
    fzf
    jq
    rar
    ripgrep
    unzip
    xclip
    zip
  ];
}
