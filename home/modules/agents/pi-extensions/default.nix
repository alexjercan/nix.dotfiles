{
  pkgs,
  sourceRoot ? ../.,
}: let
  mkPiNpmExtension = args:
    import ./mk-pi-npm-extension.nix ({
        inherit pkgs;
      }
      // args);
in {
  plannotator = mkPiNpmExtension {
    npmRoot = sourceRoot + "/pi-extensions/plannotator";
    packageName = "@plannotator/pi-extension";
  };

  voice-stt = mkPiNpmExtension {
    npmRoot = sourceRoot + "/pi-extensions/voice-stt";
    packageName = "pi-voice-stt";
  };
}
