# Agent Skills

Source for managed agent skills. `../default.nix` deploys each listed skill to:

- `~/.claude/skills/<name>` as a recursive symlink.
- `~/.agents/skills/<name>` as a recursive symlink.
- `~/.codex/skills/<name>` as real copies. Codex ignores symlinked SKILL.md.

Tool-owned `tatr` and `knowledge` skills come from their locked flake inputs.

## Workflow

Skills are explicit, focused operations:

- `understand`: investigate and maintain NOTES.md.
- `plan`: write ordered Steps and proof-bearing Definition of Done.
- `work`: implement and verify.
- `review`: judge the diff and maintain REVIEW.md.
- `compound`: write RETRO for completed work.
- `sprout`: manage isolated worktrees.
- `today`: manage the daily journal.

`afk run <task-id>` is the autonomous orchestrator. It requires an existing
TASK.md with non-empty Steps and Definition of Done. Its protocol drives work,
review, compound, final verification, and landing. It does not create or plan
tasks.

## Policy

- Every SKILL.md body: at most 250 words.
- Every description: at most 20 words.
- ASCII-adjacent writing only.
- Explicit skills set both `disable-model-invocation: true` and
  `policy.allow_implicit_invocation: false`.
- Each skill ships `agents/openai.yaml` metadata.
- A tool or template owns rules it can enforce.

## Checks

```bash
bash home/modules/agents/skills/check.sh
nix flake check
```

`check.sh` verifies structure, metadata, budgets, and writing characters. It
does not prove instruction quality. The deployment check proves every local
skill reaches all supported agent roots.
