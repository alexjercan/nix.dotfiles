# The sprout derivation, as a function of pkgs, so more than one module can
# depend on it: sprout.nix installs it, and afk.nix puts it on afk's runtime
# PATH. A module's home.packages entry cannot be referenced from another
# module, which is why this is not inline in sprout.nix.
pkgs:
pkgs.writeShellApplication {
  name = "sprout";
  runtimeInputs = [pkgs.git pkgs.fzf pkgs.tmux];
  # The implementation lives in a plain script file so it can be run and
  # integration-tested directly (see sprout-test.sh); writeShellApplication
  # still shellchecks the composed result at build time.
  text = builtins.readFile ./sprout.sh;
}
