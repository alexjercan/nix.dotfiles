{pkgs, ...}: {
  imports = [
    ./cool.nix
    ./stack.nix
    ./v.nix
  ];
}
