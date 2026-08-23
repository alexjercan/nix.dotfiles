{
  pkgs,
  sourceRoot ? ../../.,
}: {
  extension = import ../mk-pi-npm-extension.nix {
    inherit pkgs;
    npmRoot = sourceRoot + "/pi-extensions/voice-stt";
    packageName = "pi-voice-stt";
  };
}
