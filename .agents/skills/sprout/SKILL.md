---
name: sprout
description: Create, inspect, synchronize, land, and remove this project's isolated Git worktrees with Sprout.
---

# Sprout

Use Sprout only when the user requests an isolated worktree.

```bash
sprout new <feature> [--task <id>]
sprout ls
sprout show <feature>
sprout sync <feature> [--dry-run]
sprout land <feature> [--dry-run] [--remove] -m <subject>
sprout rm <feature>
```

Run work in the path printed by `sprout new`. Sync and re-verify before landing.
Land from the main checkout. Use `--remove` only when cleanup is intended.
Never remove a worktree or its tmux session without user approval.
