{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: let
  # The managed local skills, named explicitly. `skills/` also holds the
  # conformance gate (`check.sh`), which is a repository test asset, NOT a
  # skill: deploying the whole directory would put the checker in every
  # agent's skills root.
  # An explicit list is also what `checks.skills-deployment-tree` asserts
  # against the directories on disk, so a new skill cannot be added without
  # being deployed.
  localSkills = [
    "compound"
    "plan"
    "review"
    "sprout"
    "today"
    "understand"
    "work"
  ];

  # Interpolating a module-relative path literal into a STRING copies it to the
  # store as a floating, non-GC-rooted `<hash>-skills` that gets collected out
  # from under the eval cache (LESSONS.md flake-path-literal-string-coercion).
  # `${inputs.self}/...` stays inside the flake's own source closure. The
  # `home.file` sources below are path literals, not interpolations, so they
  # keep the module-relative form.
  skillsDir = "${inputs.self}/home/modules/agents/skills";

  externalSkills =
    lib.optionalAttrs (inputs.tatr ? skills && inputs.tatr.skills ? tatr) {
      tatr = inputs.tatr.skills.tatr;
    }
    // lib.optionalAttrs (inputs.agent-knowledge ? skills && inputs.agent-knowledge.skills ? knowledge) {
      knowledge = inputs.agent-knowledge.skills.knowledge;
    };

  # Each skill deploys as ONE recursive entry, so its whole tree travels: the
  # SKILL.md body, the conditional reference files beside it, and the
  # `agents/openai.yaml` that makes it reachable from codex.
  localSkillFiles = builtins.listToAttrs (lib.flatten (map (
      name: [
        {
          name = ".claude/skills/${name}";
          value = {
            source = ./skills + "/${name}";
            recursive = true;
          };
        }
        {
          name = ".agents/skills/${name}";
          value = {
            source = ./skills + "/${name}";
            recursive = true;
          };
        }
      ]
    )
    localSkills));

  copyLocalCodexSkills = lib.concatStringsSep "\n" (map (
      name: ''
        run rm -rf "$codexSkills/${name}"
        run cp -rL "${skillsDir}/${name}" "$codexSkills/${name}"
        run chmod -R u+w "$codexSkills/${name}"
      ''
    )
    localSkills);

  externalSkillFiles = builtins.listToAttrs (lib.flatten (lib.mapAttrsToList (
      name: source: [
        {
          name = ".claude/skills/${name}";
          value = {
            inherit source;
            recursive = true;
          };
        }
        {
          name = ".agents/skills/${name}";
          value = {
            inherit source;
            recursive = true;
          };
        }
      ]
    )
    externalSkills));

  copyExternalCodexSkills = lib.concatStringsSep "\n" (lib.mapAttrsToList (
      name: source: ''
        run rm -rf "$codexSkills/${name}"
        run cp -rL "${source}" "$codexSkills/${name}"
        run chmod -R u+w "$codexSkills/${name}"
      ''
    )
    externalSkills);
in {
  # Coding agent tooling and its shared configuration.
  home.packages = with pkgs; [
    agent-browser
    claude-code
    knowledge
    opencode
    codex
  ];

  # Shared guidelines for all coding agents. `AGENTS.md` is the emerging
  # cross-tool standard (opencode, codex, etc. read it natively from the home
  # directory), so we keep the source of truth in this module and point the
  # tool-specific files at it.
  home.file =
    {
      # Global instructions read by opencode, codex and other AGENTS.md-aware
      # tools when run from anywhere under the home directory.
      "AGENTS.md".source = ./AGENTS.md;

      # Claude Code reads ~/.claude/CLAUDE.md as its global memory. Import the
      # shared guidelines via the `@` include syntax so there is a single source
      # of truth. The `@` import path is resolved relative to this file
      # (~/.claude/), so reference the home-directory copy explicitly.
      ".claude/CLAUDE.md".text = ''
        @~/AGENTS.md
      '';

      # Codex reads a personal global AGENTS.md from its own home. A symlink is
      # fine here - codex resolves AGENTS.md by path and follows the link
      # (verified: the content lands in `codex debug prompt-input`).
      ".codex/AGENTS.md".source = ./AGENTS.md;
    }
    # Per-skill entries rather than one entry for `skills/`. `recursive = true`
    # links each file individually, so Claude Code and the AGENTS.md ecosystem
    # can still drop their own skills alongside the managed ones. NOTE: codex
    # does NOT read ~/.agents/skills - it discovers skills from ~/.codex/skills
    # and, unlike Claude Code, ignores a symlinked SKILL.md, so codex is fed
    # real-file copies by the activation script below, not this symlink tree.
    // localSkillFiles
    // externalSkillFiles;

  # Codex discovers user skills from ~/.codex/skills/<name>/SKILL.md, but its
  # scanner IGNORES a symlinked SKILL.md (verified with `codex debug
  # prompt-input`: a real-file skill is discovered, an identical symlinked one
  # is not) - and home.file only ever symlinks into the nix store, which is why
  # skills there stayed invisible to codex. So materialize the managed skills as
  # REAL, writable files, leaving codex's own `.system/` skills and any
  # user-installed skills untouched. (Claude Code and the AGENTS.md ecosystem
  # follow symlinks fine, so ~/.claude/skills and ~/.agents/skills stay as
  # home.file symlinks above.)
  home.activation.codexSkills = lib.hm.dag.entryAfter ["writeBoundary"] ''
    codexSkills="${config.home.homeDirectory}/.codex/skills"
    run mkdir -p "$codexSkills"
    ${copyLocalCodexSkills}
    ${copyExternalCodexSkills}
    # rm before cp (as in the loop above): a leftover symlink from an earlier
    # generation can point at the same store inode as the source (nix.optimise
    # hardlinks identical files), and `cp` aborts with "are the same file"
    # rather than overwriting. Removing first makes this idempotent.
    run rm -f "$codexSkills/README.md"
    run cp -L "${skillsDir}/README.md" "$codexSkills/README.md"
    run chmod u+w "$codexSkills/README.md"
  '';
}
