{pkgs, ...}: {
  users.users.alex = {
    isNormalUser = true;
    description = "alex";
    extraGroups = ["networkmanager" "libvirtd" "wheel" "docker" "sambashare" "dialout" "video" "audio"];
    shell = pkgs.fish;
    # The user manager runs from boot instead of from login. Scufris is a
    # background service and a set of timers under `default.target` and
    # `timers.target`: without this they do not exist until the desk is logged
    # in and are killed at logout, so the phone could not reach the service and
    # a nightly briefing in flight died with the session. The desktop companion
    # is `PartOf graphical-session.target` and still comes and goes with the
    # display.
    linger = true;
  };

  programs.fish.enable = true;
  programs.nix-ld.enable = true;

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };
}
