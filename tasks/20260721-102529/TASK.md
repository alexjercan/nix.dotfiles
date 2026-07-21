# deploy the agents skills to codex too (~/.agents/skills)

- STATUS: OPEN
- PRIORITY: 60
- TAGS: feature

## Story

As the maintainer, I want the flow-family skills (currently deployed only to
`~/.claude/skills` for Claude Code) ALSO available to Codex, so that the same
`/plan`, `/work`, `/review`, `/flow`, ... skills work in the codex CLI too.

Verified: Codex CLI (0.142.2) discovers user-scope skills from
`~/.agents/skills/<name>/SKILL.md`, using the SAME SKILL.md format (name +
description frontmatter) as Claude Code, with implicit description-matched
invocation. Confirmed empirically via `codex debug prompt-input` (a probe skill
at `~/.agents/skills/zzprobe/SKILL.md` appeared in the model-visible
`<skills_instructions>` block). So the same `./skills` source can be linked into
both locations.

## Steps

- [ ] In home/modules/agents/default.nix, add a `home.file.".agents/skills"` entry linking `./skills` (recursive = true), mirroring the existing `~/.claude/skills` link so both Claude and Codex read the same skill sources.
- [ ] Update the module comment + skills/README.md + the module AGENTS.md to say skills deploy to BOTH `~/.claude/skills` (Claude) and `~/.agents/skills` (Codex) (docs-sync rule).
- [ ] Verify: nix flake check --no-build green; build the home config / activate and confirm ~/.agents/skills is populated; `codex debug prompt-input` lists a flow skill (e.g. `plan`).

## Definition of Done

- The agents module links `./skills` into `~/.agents/skills` (cmd: `grep -n '.agents/skills' home/modules/agents/default.nix`).
- `nix flake check --no-build` is green (cmd: `nix flake check --no-build`).
- After activation, `codex debug prompt-input` lists the flow skills (manual: run it and see `plan`/`work`/`flow` under Available skills).

## Notes

- Same recursive-symlink pattern as the existing ~/.claude/skills link, same source, so Claude and Codex stay in sync from one source of truth.
- The skill BODIES reference Claude Code idioms in places; exposing them as-is is the ask. Codex-specific idiom refinement (tool names, invocation syntax) is a possible follow-up, not this task.
- Codex custom prompts (~/.codex/prompts) are deprecated by OpenAI in favor of skills; skills is the right (non-deprecated, implicit-invocable) mechanism.
