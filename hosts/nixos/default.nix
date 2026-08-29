{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ./desktop.nix
    ./maintenance.nix
    ./networking.nix
    ./services
    ./user.nix
    ./virtualization.nix
    inputs.sops-nix.nixosModules.sops
  ];

  time.timeZone = "Europe/Bucharest";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = with pkgs; [
    man-pages
    man-pages-posix
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.sauce-code-pro
  ];

  # WARNING: do not change. Pins stateful defaults (file locations, database
  # versions) to the release this system was first installed with.
  system.stateVersion = "24.05";
}
