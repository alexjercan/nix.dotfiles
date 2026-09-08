---
name: sprout
description: Create, inspect, synchronize, land, and remove isolated Git worktrees with Sprout when the user requests one.
---

# Sprout

Use Sprout only when the user requests an isolated worktree.

```bash
sprout new <feature> [--task <ID>]
sprout ls
sprout show <feature>
sprout sync <feature> [-n|--dry-run]
sprout land <feature> [-n|--dry-run] [--remove] -m <subject> [-m <body>]
sprout rm <feature> [-f|--force]
```

Run work in the path printed by `sprout new`. Sync and re-verify before
landing. Land from the main checkout.

`land` squash-merges the feature into the main checkout's branch. `--remove`
then deletes the worktree, the branch, and the tmux session.

`rm` refuses a branch whose work is not in its landing target, and keeps the
worktree and the session as they were. `--force` deletes that work, and there
is no undo. Pass `--force` only when the user says to throw the work away. When
a removal is refused, report the refusal and ask; never retry with `--force`.
