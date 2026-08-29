{...}: {
  documentation.man.cache.enable = false;

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1month
  '';

  nix.optimise = {
    automatic = true;
    dates = ["03:45"];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
