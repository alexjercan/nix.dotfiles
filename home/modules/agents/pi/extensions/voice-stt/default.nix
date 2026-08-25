{pkgs}: {
  extension = import ../mk-npm-extension.nix {
    inherit pkgs;
    npmRoot = builtins.toString ./.;
    packageName = "pi-voice-stt";
  };
}
