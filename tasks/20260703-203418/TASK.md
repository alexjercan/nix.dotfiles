# Write Claude Code skills that drive `daily` and `today` as CLI tools

- STATUS: CLOSED
- PRIORITY: 80
- TAGS: feature,historical

## Goal

Once `daily` and `today` are agent-friendly, agents still need to know they
exist and how to drive them. Add two Claude Code skills under
`home/modules/agents/skills/` (one per tool) that document the commands, the
stdout/exit-code contracts, and the agent workflows, matching the style of the
existing skills (sprout, work, ...). Skills in that directory are auto-linked
into `~/.claude/skills` by the recursive source in
`home/modules/agents/default.nix`, so no wiring change is required.

Done means:
- `home/modules/agents/skills/today/SKILL.md` and
  `home/modules/agents/skills/daily/SKILL.md` exist with proper frontmatter
  (name + selection-oriented description) and document every command, flag,
  exit code, and the machine-readable contracts (`today --create`/`--path`
  stdout, `daily --json`).
- Each skill has a concise "for agents" workflow section with real, composable
  examples (locate/create today's entry; read the day as JSON; toggle/add a
  task by index).
- The docs match the final behavior shipped in the `today` and `daily` tasks.

## Steps

- [x] Create `home/modules/agents/skills/today/SKILL.md`: frontmatter, a
      command table, the `--create`/`--path` stdout contract, exit codes, and
      agent examples. Point at `home/modules/scripts/today.nix` as the source.
- [x] Create `home/modules/agents/skills/daily/SKILL.md`: frontmatter, command
      table (read `--json`, query `--note`/`--weight`, mutate
      task/habit/macros/notes/weight), index semantics, exit codes, and agent
      examples.
- [x] Keep both consistent with existing skills: concise, imperative, a clear
      "Workflow for agents" section; reference `docs/` where useful.
- [x] Confirm no change to `agents/default.nix` is needed (recursive skills
      source picks up new files); note this in the record.

## Notes

- Depends on 20260703-203435 (today) and 20260703-203438 (daily) so the docs
  describe the final flags and contracts.
- Existing skills to match in tone/structure: `home/modules/agents/skills/{sprout,work,plan}/SKILL.md`.

## Record

**What changed.** Added two skills:
- `home/modules/agents/skills/today/SKILL.md`: documents `today` for agents -
  the `--create`/`--path` stdout-is-just-the-path contract, "never run with no
  flags (it opens $EDITOR)", idempotent create, first-entry warning, exit codes
  (0/1/2), and a create-then-read workflow that hands off to `daily`.
- `home/modules/agents/skills/daily/SKILL.md`: documents `daily` - the full
  command table (read `--json`, query `--note`/`--weight`, and the mutation
  flags), the exact `--json` object shape, the 1-based index semantics shared
  with `--toggle-task`/`--task-remove`/`--task-tomorrow-remove`, `--offset`,
  exit codes, and jq-based agent examples. Both frontmatter descriptions are
  written for skill selection and cross-reference each other.

**Decisions.** No change to `home/modules/agents/default.nix`: it links
`./skills` with `recursive = true`, so the new `today/` and `daily/` dirs are
picked up automatically (confirmed by reading the module). Kept each skill's
"For agents" section example-first and warned explicitly against the two
easy-to-hit traps (running `today` with no flags; scraping `daily`'s markdown
instead of `--json`).

**Testing.** Docs were written against the final `--help` output of the built
`today` and `daily` derivations, so the flags, defaults, and exit codes match
what shipped. Verified the recursive skills wiring needs no edit.
