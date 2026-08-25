{
  lib,
  builtInSkills,
}: {config, ...}: let
  cfg = config.programs.agents;
  collisions =
    lib.intersectLists
    (builtins.attrNames builtInSkills)
    (builtins.attrNames cfg.extraSkills);
in {
  options.programs.agents = {
    enable = lib.mkEnableOption "the agent workflow workspace";

    extraSkills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = {};
      description = "Additional named skills deployed beside built-in skills.";
    };

    finalSkills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      internal = true;
      readOnly = true;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.agents.finalSkills =
      if collisions != []
      then throw "extraSkills conflicts with built-in skills: ${lib.concatStringsSep ", " collisions}"
      else builtInSkills // cfg.extraSkills;
  };
}
