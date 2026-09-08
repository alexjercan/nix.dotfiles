{
  config,
  lib,
  ...
}: let
  cfg = config.programs.agents;

  # A skill directory is addressed by its attribute name on disk, so the name
  # must be a valid directory name every harness accepts, and the directory
  # must actually be a skill.
  invalidNames =
    builtins.filter
    (name: builtins.match "[a-z0-9]+(-[a-z0-9]+)*" name == null)
    (builtins.attrNames cfg.skills);
  missingSkillFiles =
    builtins.filter
    (name: !builtins.pathExists "${cfg.skills.${name}}/SKILL.md")
    (builtins.attrNames cfg.skills);
  checkedSkills =
    if invalidNames != []
    then throw "programs.agents has invalid skill names: ${lib.concatStringsSep ", " invalidNames}"
    else if missingSkillFiles != []
    then throw "programs.agents skill sources have no SKILL.md: ${lib.concatStringsSep ", " missingSkillFiles}"
    else cfg.skills;

  # Both roots get the same tree: `.agents/skills` is the harness-neutral
  # location and `.claude/skills` is where Claude Code looks. Deploy each file
  # rather than the directory, so an unmanaged skill can sit beside a managed
  # one in the same root.
  skillFilesFor = root:
    builtins.listToAttrs (lib.mapAttrsToList (name: source: {
        name = "${root}/${name}";
        value = {
          inherit source;
          recursive = true;
        };
      })
      checkedSkills);
in {
  # One directory per agent. The CLI packages default to `pkgs.llm-agents`, so
  # pkgs must carry the llm-agents.nix `shared-nixpkgs` overlay. It tracks
  # upstream agent releases much closer than nixpkgs does.
  imports = [
    ./agent-browser/module.nix
    ./claude-code/module.nix
    ./codex/module.nix
    ./opencode/module.nix
    ./pi/module.nix
  ];

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
      description = ''
        Named Agent Skill directories deployed for every harness. Use it for a
        skill that describes a global tool; a skill that changes per project
        stays in that project.
      '';
      example = lib.literalExpression ''
        {
          sprout = ./skills/sprout;
        }
      '';
    };

    finalSkills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      internal = true;
      readOnly = true;
      description = "The validated skills this configuration deploys.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.agents.finalSkills = checkedSkills;

    home.file =
      lib.optionalAttrs (cfg.agentsFile != null) {
        "AGENTS.md".source = cfg.agentsFile;
        # Claude Code reads its own path, so point it at the single source.
        ".claude/CLAUDE.md".text = ''
          @~/AGENTS.md
        '';
        ".codex/AGENTS.md".source = cfg.agentsFile;
      }
      // skillFilesFor ".claude/skills"
      // skillFilesFor ".agents/skills";
  };
}
