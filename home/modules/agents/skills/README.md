# Agent Skills

Drop local skill folders here (each a directory with a `SKILL.md` whose
frontmatter carries `name` and `description`). The `agents` home-manager module
links this directory plus external flake-provided skills into BOTH agent tools
that read user-scope skills:

- `~/.claude/skills` for Claude Code
- `~/.agents/skills` for the codex CLI

Both links are recursive, so each tool (or you) can still drop its own skills
alongside the managed ones. The tatr skill is owned by the tatr flake and
imported as `inputs.tatr.skills.tatr` when the locked input exposes it; keep
tool-owned skills with their tool when possible. The SKILL.md format is shared:
codex discovers
`~/.agents/skills/<name>/SKILL.md` and, like Claude Code, invokes a skill
implicitly when the task matches its `description`.
