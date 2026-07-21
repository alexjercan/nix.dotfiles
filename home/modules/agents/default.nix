{pkgs, ...}: {
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

    # The SAME skills, linked into ~/.agents/skills for the codex CLI, which
    # discovers user-scope skills from there using the identical SKILL.md format
    # (name/description frontmatter, implicit description-matched invocation) -
    # so one source of truth feeds both Claude Code and codex. `recursive = true`
    # again, so codex (or you) can drop extra skills alongside the managed ones.
    ".agents/skills" = {
      source = ./skills;
      recursive = true;
    };

    # Codex also reads a personal global AGENTS.md and user-scope skills from its
    # own home (~/.codex). Mirror the same source of truth there. `recursive =
    # true` links each file individually so codex's own ~/.codex contents
    # (auth.json, config.toml, sessions) are untouched.
    ".codex/AGENTS.md".source = ./AGENTS.md;
    ".codex/skills" = {
      source = ./skills;
      recursive = true;
    };
  };
}
