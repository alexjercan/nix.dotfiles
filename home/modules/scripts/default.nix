{pkgs, ...}: let
  sprout = pkgs.writeShellApplication {
    name = "sprout";
    runtimeInputs = [pkgs.git pkgs.fzf pkgs.tmux];
    text = builtins.readFile ./sprout.sh;
  };
in {
  home.packages = [sprout];
  home.sessionVariables.DEN_PATH = "/home/alex/personal/the-den";
}
