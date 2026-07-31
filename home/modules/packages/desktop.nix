{pkgs, ...}: {
  home.packages = with pkgs; [
    dconf
    feh
    i3lock
    libnotify
    lxappearance
    networkmanager-openvpn
    networkmanagerapplet
    nitrogen
    openvpn
    pcmanfm
    pw-volume
    pwvucontrol
    scrot
    virt-manager
  ];
}
