# Do not repeat a package a feature module already installs (kitty, dunst,
# i3status-rust): home-manager raises a file collision.
{...}: {
  imports = [
    ./cli.nix
    ./dev.nix
    ./media.nix
    ./apps.nix
    ./games.nix
    ./desktop.nix
    ./fonts.nix
  ];
}
