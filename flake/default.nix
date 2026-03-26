{...}: {
  systems = ["x86_64-linux"];

  imports = [
    ./nixos-configurations.nix
    ./home-configurations.nix
  ];
}
