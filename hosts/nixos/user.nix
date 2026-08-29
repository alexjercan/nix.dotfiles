{pkgs, ...}: {
  users.users.alex = {
    isNormalUser = true;
    description = "alex";
    extraGroups = ["networkmanager" "libvirtd" "wheel" "docker" "sambashare" "dialout" "video" "audio"];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
  programs.nix-ld.enable = true;

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };
}
