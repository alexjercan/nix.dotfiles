{...}: {
  imports = [./samba.nix];

  services.logmein-hamachi.enable = true;
}
