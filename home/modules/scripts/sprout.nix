{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "sprout";
      runtimeInputs = [pkgs.git pkgs.fzf pkgs.tmux];
      # The implementation lives in a plain script file so it can be run and
      # integration-tested directly (see sprout-test.sh); writeShellApplication
      # still shellchecks the composed result at build time.
      text = builtins.readFile ./sprout.sh;
    })
  ];
}
