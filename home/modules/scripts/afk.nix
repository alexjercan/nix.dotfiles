{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "afk";
      # claude-code is the engine; tatr and git are the authorities afk checks
      # every routing decision against; sprout performs the landing; jq parses
      # the stream-json events; util-linux provides uuidgen for the session IDs.
      runtimeInputs = [
        pkgs.claude-code
        pkgs.tatr
        pkgs.git
        (import ./sprout-pkg.nix pkgs)
        pkgs.jq
        pkgs.gnused
        pkgs.gawk
        pkgs.coreutils
        pkgs.util-linux
      ];
      # The implementation lives in a plain script file so it can be run and
      # integration-tested directly (see afk-test.sh); writeShellApplication
      # still shellchecks the composed result at build time.
      text = builtins.readFile ./afk.sh;
    })
  ];
}
