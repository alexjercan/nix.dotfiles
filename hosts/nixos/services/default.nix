{...}: {
  imports = [
    ./llama-cpp.nix
    ./samba.nix
  ];

  services.logmein-hamachi.enable = true;
}
