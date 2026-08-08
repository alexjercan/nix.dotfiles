---
name: sprout
description: Manage isolated git worktrees with sprout. Use for /sprout.
disable-model-invocation: true
---

# Sprout

Manage feature worktrees with the `sprout` CLI.

## Commands

```bash
cd "$(sprout new <feature> [--task <id>])"
cd "$(sprout show <feature>)"
sprout ls
sprout sync <feature> [-n]
sprout land <feature> [-n] -m "<subject>"
sprout rm <feature>
```

* `new`: create or reuse a feature worktree from current HEAD.
* `show`: print its path.
* `ls`: list branch, task, and path.
* `sync`: merge the landing target into the feature. `-n` probes conflicts.
* `land`: squash-merge into the landing target and remove the worktree.
* `rm`: remove worktree and branch. Destructive.
* One task per worktree.
* Use absolute paths across agent calls.
* Run `sprout land` from main, never from the feature worktree.
* Recover automatically only when the action is safe, reversible, and owned
  by the task. Stop for destructive, uncertain, or unrelated user changes.
* A dirty main checkout blocks landing. Report exact paths. Do not stash
  unrelated changes without user permission.
