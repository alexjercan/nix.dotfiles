{piExtensions}: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.agents;
  voiceCfg = cfg.pi.voiceStt;
  json = pkgs.formats.json {};
  voiceConfigPath = "${config.home.homeDirectory}/.config/pi-voice-stt/config.json";
in {
  options.programs.agents.pi = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether the agent workspace enables Pi.";
    };

    extensions = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.path lib.types.str);
      default = [];
      description = "Pi extensions to load.";
    };

    themes = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = "Pi themes to load.";
    };

    voiceStt = {
      enable = lib.mkEnableOption "local speech-to-text in Pi";

      extension = lib.mkOption {
        type = lib.types.package;
        default = piExtensions.voice-stt;
        defaultText = lib.literalExpression "piExtensions.voice-stt";
        description = "Pinned pi-voice-stt extension package.";
      };

      ffmpegPackage = lib.mkOption {
        type = lib.types.package;
        default = pkgs.ffmpeg;
        defaultText = lib.literalExpression "pkgs.ffmpeg";
        description = "FFmpeg package used for microphone capture.";
      };

      settings = lib.mkOption {
        inherit (json) type;
        default = {};
        description = "pi-voice-stt JSON configuration.";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      programs.pi.coding-agent = {
        enable = cfg.pi.enable;
        extensions = cfg.pi.extensions ++ lib.optional voiceCfg.enable voiceCfg.extension;
        themes = cfg.pi.themes;
      };
    }

    (lib.mkIf (cfg.pi.enable && voiceCfg.enable) {
      home.packages = [voiceCfg.ffmpegPackage];
      home.sessionVariables.PI_STT_CONFIG = voiceConfigPath;
      home.file.".config/pi-voice-stt/config.json".source = json.generate "pi-voice-stt-config.json" voiceCfg.settings;
    })
  ]);
}
