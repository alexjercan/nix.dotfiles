{pkgs, ...}: {
  imports = [
    ./cool.nix
    ./stack.nix
    ./v.nix
    ./c3.nix
  ];
}
