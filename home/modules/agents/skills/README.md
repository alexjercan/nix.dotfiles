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
not by globbing this directory - `check.sh` and `fixtures/` live here too and
are test assets, not skills. `checks.skills-deployment-tree` asserts the list
and the directories on disk agree, so a new skill folder cannot be added
without being deployed.

Tool-owned skills come from their own flake: the tatr skill is imported as
`inputs.tatr.skills.tatr` when the locked input exposes it. Keep tool-owned
skills with their tool.

## Context budgets

The flow family is `flow plan work review spike compound lessons sprout`.
`flow` is a dispatcher; every other skill owns one phase. Branch-specific
material lives in a conditional reference, read only when its condition holds
and pointed at from a `## Load on demand` section in this shape:

```markdown
## Load on demand

- the task is a bug, crash, regression or falsification -> `bug.md`
```

The condition text before the arrow is what the disclosure fixtures assert
against, so it has to name the branch in words, on the arrow's own line.

A skill whose work comes in several shapes routes to them the same way. `spike`
names four modes - research, logic prototype, UI prototype, and mixed evidence
- over two references: logic and UI prototypes share every storage and
retention rule, so a file each would duplicate rather than separate them. One
mode may reach two references, as mixed evidence does.

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
| `flow/SKILL.md` body | at most 500 words |
| Any other `SKILL.md` body | at most 800 words |
| One conditional reference | at most 1000 words, one level deep |
| A phase's `## Output` contract | at most 150 words |

Every row is the inclusive limit the gate compares against, so a surface
sitting exactly on its number is conformant and has no headroom.

A phase's `## Output` section is the single owner of BOTH its user-facing chat
report and the handoff it returns to `flow`: they are the same text, so one
budget governs both, and the durable records hold everything else. The report
itself states its own word cap, which the output fixtures assert.

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
bash home/modules/agents/skills/check.sh                # conformance gate
bash home/modules/agents/skills/check.sh --self-test    # prove the gate can fail
bash home/modules/agents/skills/check.sh --fixture <case>  # one fixture case
nix flake check                                         # both, plus deployment
```

`--fixture <case>` runs the fixture whose `name:` matches and nothing else,
printing `fixture <case>: ok` when it passes. The bare gate prints only
findings, so a task whose Definition of Done rests on one fixture names that
case as its `cmd:` proof.

`check.sh` owns the skill TEXTS: budgets, the reference graph, substituted
typographic glyphs (en/em dash, smart quotes, ellipsis, arrows - not every
non-ASCII byte, since a skill may legitimately quote data containing one), the
invocation policy, duplicated paragraphs, and the fixtures under `fixtures/`.
`check.sh --rules` prints every rule it can report; `--self-test` proves each
of them can fire.
tatr owns the task RECORD schemas (`tatr check`). The deployment check owns
whether the files reach an agent.

The fixtures are structural proofs over the skill texts: they show the suite is
shaped so only the intended files are reachable on a branch and only the
intended skills are implicitly invocable. Whether a given model then obeys that
shape is a manual check, not something a deterministic gate can assert.

There are four fixture kinds. `disclosure/` states what a phase may load on one
branch and what it may not; `invocation/` states which skills the two agent
tools may trigger implicitly; `output/` states what a phase's chat report must
contain and its word cap; `content/` states which rules a reference file or one
of its `##` sections must still say. The first three prove a file is reachable
and bounded, which is exactly what a reference that kept its pointer while
losing its rule would also pass - `content/` is what closes that gap.
