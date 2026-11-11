{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.agents;
  extCfg = cfg.pi.extensions.pi-btw;
  self = import ./. {inherit pkgs;};
  json = pkgs.formats.json {};
in {
  options.programs.agents.pi.extensions.pi-btw = {
    enable = lib.mkEnableOption "Pi side threads and the Neovim bridge";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.extension;
      defaultText = lib.literalExpression "the pinned pi-btw package";
      description = "Pinned pi-btw extension package.";
    };

    settings = lib.mkOption {
      inherit (json) type;
      default = {};
      example = {
        model = "openai-codex/gpt-6-luna";
        thinkingLevel = "medium";
      };
      description = "The `btw` key of Pi's settings.json: side-thread `model` and `thinkingLevel`.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = !extCfg.enable || cfg.pi.enable;
          message = "programs.agents.pi.extensions.pi-btw.enable requires programs.agents.pi.enable";
        }
      ];
    }

    (lib.mkIf (cfg.pi.enable && extCfg.enable && extCfg.settings != {}) {
      programs.agents.pi.settings.btw = extCfg.settings;
    })
  ]);
}
