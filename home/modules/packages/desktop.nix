{pkgs, ...}: {
  home.packages = with pkgs; [
    dconf
    feh
    i3lock
    libnotify
    lxappearance
    networkmanager-openvpn
    networkmanagerapplet
    openvpn
    pcmanfm
    pwvucontrol
    scrot
    virt-manager
    wireplumber
  ];
}
