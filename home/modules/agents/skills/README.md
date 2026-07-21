# Agent Skills

Drop skill folders here (each a directory with a `SKILL.md` whose frontmatter
carries `name` and `description`). The `agents` home-manager module links this
directory into BOTH agent tools that read user-scope skills, from this one
source of truth:

- `~/.claude/skills` for Claude Code
- `~/.agents/skills` for the codex CLI

Both links are recursive, so each tool (or you) can still drop its own skills
alongside the managed ones. The SKILL.md format is shared: codex discovers
`~/.agents/skills/<name>/SKILL.md` and, like Claude Code, invokes a skill
implicitly when the task matches its `description`.
