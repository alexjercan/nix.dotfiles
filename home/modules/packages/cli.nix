{pkgs, ...}: {
  home.packages = with pkgs; [
    bat
    btop
    dua
    dust
    fastfetch
    fd
    file
    fzf
    htop
    jq
    lsof
    nvtopPackages.nvidia
    pv
    rar
    ripgrep
    unzip
    wget
    xclip
    zip
  ];
}
