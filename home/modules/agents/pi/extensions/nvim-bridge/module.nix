{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.agents;
  extCfg = cfg.pi.extensions.nvim-bridge;
  self = import ./. {inherit pkgs;};
in {
  options.programs.agents.pi.extensions.nvim-bridge = {
    enable = lib.mkEnableOption "the Neovim-to-Pi tmux bridge";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.extension;
      defaultText = lib.literalExpression "the local Neovim bridge extension package";
      description = "Local Neovim bridge extension package.";
    };
  };

  # The Pi process publishes its socket on its own tmux pane. A Neovim in the
  # same session finds it through window 2, so no global process scan is needed.
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !extCfg.enable || cfg.pi.enable;
        message = "programs.agents.pi.extensions.nvim-bridge.enable requires programs.agents.pi.enable";
      }
    ];
  };
}
