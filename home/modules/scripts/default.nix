{pkgs, ...}: {
  imports = [
    ./sprout.nix
  ];

  # The unified `today` CLI (github:alexjercan/today) replaces the old `today` +
  # `daily` bash scripts: one command with non-interactive `--json` subcommands
  # (path/create/show + task/habit/weight/macros/note). Provided via
  # inputs.today.overlays.default (see flake/home-configurations.nix). It reads
  # the den from --den, then $DEN_PATH, then ~/personal/the-den.
  home.packages = [pkgs.today];
  home.sessionVariables.DEN_PATH = "/home/alex/personal/the-den";
}
