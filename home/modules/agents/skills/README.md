# Agent Skills

Source of the managed agent skills. The `agents` home-manager module
(`../default.nix`) deploys each one into all three locations that matter:

- `~/.claude/skills/<name>` - Claude Code, a recursive symlink tree.
- `~/.agents/skills/<name>` - the shared AGENTS.md ecosystem, same tree.
- `~/.codex/skills/<name>` - the codex CLI, REAL writable file copies made by
  the activation script. Codex's scanner ignores a symlinked `SKILL.md`, so a
  symlink tree is invisible to it.

Both link trees are recursive, so each tool (or you) can still drop its own
skills alongside the managed ones.

## Layout

```
<name>/
  SKILL.md            frontmatter + the always-loaded body
  <branch>.md         conditional references, loaded only on their branch
  agents/openai.yaml  codex display metadata
```

Skills are deployed from the explicit `localSkills` list in `../default.nix`,
not by globbing this directory - `check.sh` lives here too and is a test asset,
not a skill. `checks.skills-deployment-tree` asserts the list
and the directories on disk agree, so a new skill folder cannot be added
without being deployed.

Tool-owned skills come from their own flakes: `tatr` from
`inputs.tatr.skills.tatr`, and `knowledge` from
`inputs.agent-knowledge.skills.knowledge`, when the locked inputs expose them.
Keep tool-owned skills with their tools.

## Context budgets

The flow family is `flow understand plan work review compound sprout`.
`flow` dispatches the understand, plan, work, review and compound
phases; `sprout` is the explicit worktree helper. The `today` and `knowledge` tools pay the same body
cap. Branch-specific material lives in a conditional reference, read only when
its condition holds and pointed at from a `## Load on demand` section in this
shape:

```markdown
## Load on demand

- the task is a bug, crash, regression or falsification -> `bug.md`
```

`check.sh` requires condition text before the arrow, so it has to name the
branch in words, on the arrow's own line.

A skill whose work comes in several shapes routes to them the same way.
`understand` reaches `evidence.md` for both an external fact and a runnable
prototype, because the two share every citation, storage and retention rule; a
file each would duplicate them rather than separate them. That reference is
also where the retired `spike` skill went - research before a decision is the
understand phase, not a phase of its own. See
`tasks/20260730-142052/SPIKE.md` for the split it used to carry.

A phase that can run several independent contexts keeps that material behind
the same door. `plan/lanes.md` and `review/lanes.md` hold the lane-selection
rules, the per-lane cap, and the synthesis or aggregation contract, so an
ordinary single-context run never loads them. They are two files rather than
one shared file because a pointer resolves inside its own skill directory and
`duplicated-paragraph` rejects a rule pasted verbatim into both; each states
its own phase's version. See `tasks/20260730-154958/DECISION.md`.

| Surface | Budget |
| --- | --- |
| One description | at most 30 words |
| All flow-family descriptions | at most 200 words |
| `flow/SKILL.md` body | at most 300 words |
| Any other `SKILL.md` body | at most 400 words |
| One conditional reference | at most 600 words, one level deep |
| A phase's `## Output` contract | at most 150 words |

Every row is the inclusive limit the gate compares against, so a surface
sitting exactly on its number is conformant and has no headroom.

A phase's `## Output` section is the single owner of BOTH its user-facing chat
report and the handoff it returns to `flow`: they are the same text, so one
budget governs both, and the durable records hold everything else. The report
itself states its own word cap.

Budgets are a failure signal, not licence to drop a required guard. A rule that
a tool or template can enforce belongs there instead, and the skill prose it
replaces is deleted in the same change.

## Invocation policy

Only skills that must fire implicitly, or that `flow` dispatches by name, stay
model-invocable. Everything else declares `disable-model-invocation: true` and
is reachable by slash command only. Both agent tools read that one frontmatter
key, so the policy is declared once.

## Checks

```bash
bash home/modules/agents/skills/check.sh   # conformance gate
nix flake check                            # that, plus the deployment tree
```

`check.sh` owns the skill TEXTS: budgets, the reference graph, substituted
typographic glyphs (en/em dash, smart quotes, ellipsis, arrows - not every
non-ASCII byte, since a skill may legitimately quote data containing one), the
invocation policy, duplicated paragraphs, a present `## Output` contract, and
`direct-state-edit` (no flow-family skill may ORDER a lifecycle marker -
ACTIVITY, GATES or RESOLUTION - written by hand; `tatr flow`, `tatr rewind` and
`tatr close` own those writes), and `unrooted-tatr-call` (a `tatr`
command naming a task must name the root that owns it, `-r <task-root>`,
because a sprout worktree owns its records while the task is in flight and the
shell's cwd is the main checkout). `check.sh --rules` prints every rule it can
report.
tatr owns the task RECORD schemas (`tatr check`). The deployment check owns
whether the files reach an agent.

Every rule here is STRUCTURAL: a property of the files that a static read
settles in about two seconds. The gate does not assert that a reference still
STATES the rule it exists to carry. A fixture suite did that for a while and
was removed - it cost more to iterate on than it caught, and it made every
prose edit a two-file edit. Whether a skill says the right thing is a review
question, and whether a model then obeys it was never something a deterministic
gate could answer.
