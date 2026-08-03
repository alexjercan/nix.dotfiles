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
cd "$(sprout new <feature> [--task <id>])"
cd "$(sprout show <feature>)"
sprout ls
sprout sync <feature> [-n]
sprout land <feature> [-n] -m "<subject>" [-m "<body>"]
sprout rm <feature>
```

- `new`/`show` print only the path. New branches start at current HEAD and
  reuse an existing branch. `--task` validates a tatr-shaped ID and stores the
  association in Git's worktree-local config; it does not require tatr.
- Names may contain `/`; never empty, leading `-`/`/`, or a `..` segment.
- `ls` is project-scoped. Each row prints `BRANCH TASK PATH`; missing task
  associations and detached branches show `-`.
- `rm` force-deletes the branch and tmux session. Use only when truly done;
  nonzero means nothing existed.
- `new` records the main checkout's current branch as `sprout.target`; a
  detached one records nothing. `sync` and `land` prefer it, falling back to
  that current branch when absent. Both refuse once a recorded target is
  renamed or deleted; the escape is `git config --worktree --unset
  sprout.target`.
- `sync` merges that target into the branch INSIDE its worktree; a conflict is
  left there to resolve. `-n` probes without writing, printing the paths that
  would conflict.
- `land` squash-merges one commit into the main checkout's current branch,
  then removes the feature. It refuses dirty tracked main, detached HEAD,
  invocation inside the feature, a target the main checkout no longer has
  checked out, or a feature missing the target tip. Failure rolls main back to
  a clean tracked tree. `-n` runs every guard and writes nothing.

## Rules

- One task per feature/worktree. Sprout owns no task, plan, or review state.
- Run `sprout land` alone from main, never chained from the worktree.
- Use absolute paths across calls; shell cwd does not persist.
- Accept cold per-worktree caches. Never share build directories.
- Gitignored files exist only per worktree; after landing removals, clean
  ignored main-tree leftovers explicitly.

## Load on demand

- interactive tmux mode or CLI design background -> `reference.md`
