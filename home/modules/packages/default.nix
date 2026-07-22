# Topical package sets, split out of the old flat `home.packages` list in
# home/alex/default.nix. Each sub-module just declares `home.packages`; they are
# merged by home-manager. Packages that a feature module already provides
# (kitty, dunst, i3status-rust) are NOT repeated here.
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
