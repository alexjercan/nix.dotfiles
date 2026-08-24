{sourceRoot ? ../../.}: {
  lib,
  pkgs,
  ...
}: let
  self = import ./. {inherit pkgs sourceRoot;};
in {
  options.programs.agents.pi.extensions.quick-review = {
    enable = lib.mkEnableOption "the Quick Review Pi extension";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.extension;
      defaultText = lib.literalExpression "the pinned Quick Review package";
      description = "Pinned Quick Review extension package.";
    };
  };
}
