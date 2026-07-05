---
name: tatr
description: Track work items with the tatr CLI, which stores tasks as markdown files under a tasks/ directory so they are versioned with the code. Use this skill whenever the project contains a tasks/ directory, whenever the user mentions tasks, TODOs, backlog, TASK.md, or task tracking, and whenever planning or breaking down multi-step work that should persist across sessions. Also use it before starting work (check the backlog) and after finishing work (close the task).
---

# Tatr - Task Tracking for Code Projects

Tatr stores tasks as `tasks/<YYYYMMDD-HHMMSS>/TASK.md` files. The timestamp directory is the task ID. Tatr searches upward from the current directory to find `tasks/`, so it works from anywhere inside the project.

## Commands

```bash
tatr new "Title" [-p <priority>] [-t tag1,tag2] [-s OPEN|IN_PROGRESS|CLOSED]
tatr ls [--sort created|priority|title] [-R] [-f '<query>']
tatr show <id>
tatr edit <id> [-T "New title"] [-p <priority>] [-t tag1,tag2] [-s <status>]
tatr rm <id>
```

- `tatr new` creates the task directory and TASK.md, and prints the task ID. Default status is OPEN, default priority 0.
- `tatr ls` prints one line per task: `<filepath>: [PRIORITY: N, TAGS: ...] Title`. `-R` recurses into nested `tasks/` dirs; `-f` filters (see below).
- `tatr show <id>` prints a single task's full details: title, status, priority, tags, and the whole description body, with a clickable file path.
- `tatr edit <id>` updates fields in place without opening an editor. Only the flags you pass change; everything else, including the description body, is preserved. `-t` replaces the tag set (it does not merge). An invalid status is rejected and the file is left untouched. This is how automation moves a task OPEN -> IN_PROGRESS -> CLOSED.
- `tatr rm <id>` deletes the task's directory (its TASK.md and anything else inside it). It only ever touches the validated `tasks/<id>/` path.

All of `show`, `edit` and `rm` take the task ID (the `YYYYMMDD-HHMMSS` directory name) and exit non-zero with a clear message if the ID is malformed or the task does not exist.

## Filtering

`tatr ls -f` takes a small query language over task fields (`:status`, `:priority`, `:tags`), with operators `eq`, `contains`, `in` (with `[...]` lists) and the connectives `and`, `or`, `not`, grouped with parentheses:

```bash
tatr ls -f '(:status eq OPEN)'
tatr ls -f ':tags contains feature'
tatr ls -f '(:status eq OPEN) and (:tags contains feature)'
```

Filtering composes with `--sort` and `-R` (applied per section in recursive mode). Prefer `-f` over piping `tatr ls` through `grep`.

## Task File Format

Keep this exact structure when editing or creating TASK.md files by hand:

```markdown
# Task Title

- STATUS: OPEN
- PRIORITY: 100
- TAGS: feature, security

Free-form description. Use this area for requirements, implementation
notes, and progress logs.
```

Status values are case-sensitive: `OPEN`, `IN_PROGRESS`, `CLOSED`. Priority is a non-negative integer, higher = more important (0 low, 50 medium, 100 high).

Prefer `tatr edit` for the metadata fields (status, priority, tags, title) so the header stays well-formed; hand-edit the file only for the free-form description body below the metadata.

## Workflow

**Picking up work:**
1. `tatr ls --sort priority` (or `tatr ls -f '(:status eq OPEN)'`) to see the backlog.
2. `tatr show <id>` to read the full task, then `tatr edit <id> -s IN_PROGRESS` to claim it.
3. Append implementation notes to the description as you go (edit TASK.md directly for the free-form body; `tatr edit` handles the metadata fields).

**Finishing work:**
1. `tatr edit <id> -s CLOSED`.
2. In the description, record what changed and why, difficulties or bugs hit along the way, and brief self-reflection on what could have gone better. Future sessions read this.
3. Commit the TASK.md change together with the code changes.

**Planning a feature:**
- Break it into multiple tasks with `tatr new`, one per component, with priorities that encode the intended order.
- Use consistent tags within the project (`feature`, `bug`, `refactor`, `testing`, `docs`, `security`, `performance`).
- Create tasks for any non-trivial follow-up work discovered mid-session instead of leaving TODO comments in code.

## Implementing a Task

A tatr task is a tracking record, not the work itself. When the ask is to
"implement task <id>" (or to pick one off the backlog and build it), that means
the full plan-work-review-compound cycle, not just editing TASK.md:

1. Sprout an isolated worktree and feature branch for the task (see the sprout
   skill) so implementation never collides with the main checkout or other
   tasks in flight.
2. Implement it with `/work`, which does the sprout for you, sets STATUS to
   `IN_PROGRESS`, ticks the Steps, and writes tests inside that worktree.
3. Review with `/review` and address findings until the verdict is APPROVE.
4. Retro with `/compound` once the task is CLOSED.

`/flow` runs this whole loop end to end for you; reach for the individual
skills to step through it by hand. If a task has no Steps yet (created ad hoc),
plan it first with `/plan`; and when even planning is premature because the
direction itself is unknown, `/spike` explores it first and seeds the coarse
tasks that plan then breaks into steps - so the fullest cycle is spike, plan,
work, review, compound. Tatr itself only owns the file: creating it, and
reading or updating its STATUS, Steps and notes.

## Gotchas

- "No 'tasks' directory found": create `tasks/` at the project root first.
- A task only shows in `tatr ls` if its directory matches `YYYYMMDD-HHMMSS` and contains a well-formed TASK.md.
- Timestamps are local time.
