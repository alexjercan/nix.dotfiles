{
  pkgs,
  config,
  lib,
  ...
}: {
  # Coding agent tooling and its shared configuration.
  home.packages = with pkgs; [
    agent-browser
    claude-code
    opencode
    codex
  ];

  # Shared guidelines for all coding agents. `AGENTS.md` is the emerging
  # cross-tool standard (opencode, codex, etc. read it natively from the home
  # directory), so we keep the source of truth in this module and point the
  # tool-specific files at it.
  home.file = {
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

    # Skills folder linked into ~/.claude/skills. `recursive = true` links each
    # file individually rather than the whole directory, so Claude Code can
    # still drop its own skills into ~/.claude/skills alongside the managed ones.
    ".claude/skills" = {
      source = ./skills;
      recursive = true;
    };

    # The SAME skills, linked into ~/.agents/skills for AGENTS.md-ecosystem
    # tools that read that shared location. NOTE: codex does NOT read here - it
    # discovers skills from ~/.codex/skills and, unlike Claude Code, ignores
    # symlinked SKILL.md, so codex is fed real-file copies by the activation
    # script below, not this symlink tree.
    ".agents/skills" = {
      source = ./skills;
      recursive = true;
    };

    # Codex reads a personal global AGENTS.md from its own home. A symlink is
    # fine here - codex resolves AGENTS.md by path and follows the link
    # (verified: the content lands in `codex debug prompt-input`).
    ".codex/AGENTS.md".source = ./AGENTS.md;
  };

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
    for src in ${./skills}/*/; do
      name="$(basename "$src")"
      run rm -rf "$codexSkills/$name"
      run cp -rL "$src" "$codexSkills/$name"
      run chmod -R u+w "$codexSkills/$name"
    done
    run cp -fL ${./skills}/README.md "$codexSkills/README.md"
    run chmod u+w "$codexSkills/README.md"
  '';
}
