{agentPackages}: {
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.agents;
  candidateSkills = cfg.skills // cfg.internalSkills;
  invalidNames =
    builtins.filter
    (name: builtins.match "[a-z0-9]+(-[a-z0-9]+)*" name == null)
    (builtins.attrNames candidateSkills);
  missingSkillFiles =
    builtins.filter
    (name: !builtins.pathExists "${candidateSkills.${name}}/SKILL.md")
    (builtins.attrNames candidateSkills);
  checkedSkills =
    if invalidNames != []
    then throw "programs.agents has invalid skill names: ${lib.concatStringsSep ", " invalidNames}"
    else if missingSkillFiles != []
    then throw "programs.agents skill sources have no SKILL.md: ${lib.concatStringsSep ", " missingSkillFiles}"
    else candidateSkills;

  skillFilesFor = root:
    builtins.listToAttrs (lib.mapAttrsToList (name: source: {
        name = "${root}/${name}";
        value = {
          inherit source;
          recursive = true;
        };
      })
      checkedSkills);

  codexSkillArgs = lib.concatMapStringsSep " " lib.escapeShellArg (lib.flatten (lib.mapAttrsToList
    (name: source: [name (builtins.toString source)])
    checkedSkills));
in {
  options.programs.agents = {
    enable = lib.mkEnableOption "the agent workflow workspace";

    agentsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Source AGENTS.md file, or null to deploy no global instructions.";
      example = lib.literalExpression "./AGENTS.md";
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = {};
      description = "Named Agent Skill directories to deploy on every supported harness.";
      example = lib.literalExpression ''
        {
          release = ./skills/release;
          today = inputs.today.skills.today;
        }
      '';
    };

    internalSkills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = {};
      internal = true;
    };

    finalSkills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      internal = true;
      readOnly = true;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      programs.agents.finalSkills = checkedSkills;

      home.file =
        lib.optionalAttrs (cfg.agentsFile != null) {
          "AGENTS.md".source = cfg.agentsFile;
          ".claude/CLAUDE.md".text = ''
            @~/AGENTS.md
          '';
          ".codex/AGENTS.md".source = cfg.agentsFile;
        }
        // skillFilesFor ".claude/skills"
        // skillFilesFor ".agents/skills";
    })

    {
      home.activation.agentsCodexSkills = lib.hm.dag.entryAfter ["writeBoundary"] ''
        codexSkills="${config.home.homeDirectory}/.codex/skills"
        ${lib.getExe agentPackages.deploy-codex-skills} "$codexSkills"${lib.optionalString cfg.enable " ${codexSkillArgs}"}
      '';
    }
  ];
}
