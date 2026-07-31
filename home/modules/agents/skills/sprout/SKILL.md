---
name: sprout
description: Manage git worktrees with the sprout CLI so parallel agents do not collide. Use for `/sprout`, worktrees, or parallel branches.
disable-model-invocation: true
---

# Sprout - Isolated Git Worktrees

Creates one feature worktree under
`${XDG_CACHE_HOME:-$HOME/.cache}/sprouts/<project>/<feature>`. `sprout help`
prints usage. `work`/`flow` embed their commands; use this skill directly for
worktree operations.

## Commands

```bash
cd "$(sprout new <feature>)"
cd "$(sprout show <feature>)"
sprout ls
sprout land <feature> -m "<subject>" [-m "<body>"]
sprout rm <feature>
```

- `new`/`show` print only the path. New branches start at current HEAD and
  reuse an existing branch.
- Names may contain `/`; never empty, leading `-`/`/`, or a `..` segment.
- `ls` is project-scoped; detached worktrees show branch `-`.
- `rm` force-deletes the branch and tmux session. Use only when truly done;
  nonzero means nothing existed.
- `land` squash-merges one commit into the main checkout's current branch,
  then removes the feature. It refuses dirty tracked main, detached HEAD,
  invocation inside the feature, or a feature missing the target tip. Failure
  rolls main back to a clean tracked tree.

## Rules

- One task per feature/worktree. Sprout owns no task, plan, or review state.
- Run `sprout land` alone from main, never chained from the worktree.
- Use absolute paths across calls; shell cwd does not persist.
- Accept cold per-worktree caches. Never share build directories.
- Gitignored files exist only per worktree; after landing removals, clean
  ignored main-tree leftovers explicitly.

## Load on demand

- interactive tmux mode or CLI design background -> `reference.md`
