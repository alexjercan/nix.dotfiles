---
name: tatr
description: Track work items with the tatr CLI, which stores tasks as markdown files under a tasks/ directory so they are versioned with the code. Use this skill whenever the project contains a tasks/ directory, whenever the user mentions tasks, TODOs, backlog, TASK.md, or task tracking, and whenever planning or breaking down multi-step work that should persist across sessions. Also use it before starting work (check the backlog) and after finishing work (close the task).
---

# Tatr - Task Tracking for Code Projects

Tatr stores tasks as `tasks/<YYYYMMDD-HHMMSS>/TASK.md` files. The timestamp directory is the task ID. Tatr searches upward from the current directory to find `tasks/`, so it works from anywhere inside the project; `-r ROOT` runs it against another directory.

## Commands

```bash
tatr [-r ROOT] <subcommand> [options]

tatr new "Title" [-p <priority>] [-t tag1,tag2] [-s OPEN|IN_PROGRESS|CLOSED] [-b <file>]
tatr ls [-s created|priority|title] [-R] [-f '<query>']
tatr show <id>
tatr edit <id> [-T "New title"] [-p <priority>] [-t tag1,tag2] [-s <status>]
tatr rm <id>
tatr check [<id>] [-S|--strict] [-L|--ledger <file>]
```

- `tatr new` creates the task directory and TASK.md, and prints the task ID. Default status is OPEN, default priority 0. `-b/--body-file <file>` seeds the description body from a file (`-` reads stdin) - prefer it over creating an empty task and editing the file afterwards. If the generated ID already exists (two `new` calls in the same second), tatr FAILS instead of overwriting; just retry for a fresh ID.
- `tatr ls` prints one line per task: `<filepath>: [PRIORITY: N, TAGS: ...] Title`. `-s/--sort` orders by `created` (default), `priority` (descending), or `title`; `-R` recurses into nested `tasks/` dirs (one section per project); `-f` filters (see below).
- `tatr show <id>` prints a single task's full details: title, status, priority, tags, and the whole description body, with a clickable file path.
- `tatr edit <id>` updates fields in place without opening an editor. Only the flags you pass change; everything else, including the description body, is preserved. `-t` replaces the tag set (it does not merge). An invalid status is rejected and the file is left untouched. This is how automation moves a task OPEN -> IN_PROGRESS -> CLOSED.
- `tatr rm <id>` deletes the task's directory (its TASK.md and anything else inside it). It only ever touches the validated `tasks/<id>/` path.
- `tatr check` lints task artifacts for process drift: findings print one per line as `<id>: <rule>: <detail>`, exit 1 on any finding, exit 0 and silent when clean. Default rules: `closed-unchecked` (CLOSED task with unchecked `- [ ]` items under `## Steps`), `closed-not-approved` (latest `- VERDICT:` token in REVIEW.md is not APPROVE, or no verdict at all), `bad-severity` (a REVIEW.md finding severity outside BLOCKER|MAJOR|MINOR|NIT), `malformed-header` (missing/unparseable TASK.md, or a STATUS token that is not exactly OPEN/IN_PROGRESS/CLOSED - whitespace and line endings count), `bad-decision-status` (a task's `DECISION.md`, when present, has a `- STATUS:` value that is not `ACCEPTED` nor `SUPERSEDED by <ref>`, or no STATUS line), `dangling-supersede` (a `DECISION.md` supersede reference - in a `SUPERSEDED by <ref>` status or a `- Supersedes: <ref>` line - does not resolve to an existing `tasks/<id>/DECISION.md`). The two `DECISION.md` rules are presence-gated - a task with no `DECISION.md` is never flagged, so they need no migration of existing tasks. `-S/--strict` adds `closed-missing-review`/`closed-missing-retro` for CLOSED tasks lacking those files; `-L/--ledger <file>` adds `promotion-stalled` for a lesson at `(x3)` or more outside the ledger's "## Pending promotions" section (bare counts only: an annotated `(x3, ...)` is the promotion marker and is exempt); ledger findings print a literal `ledger` in the id slot, and an unreadable ledger path is itself a finding. With `<id>` it checks that one task.

All of `show`, `edit`, `rm` and per-ID `check` take the task ID (the `YYYYMMDD-HHMMSS` directory name) and exit non-zero with a clear message if the ID is malformed or the task does not exist.

## Filtering

`tatr ls -f` takes a small query language over task fields (`:status`, `:priority`, `:tags`), with operators `eq`, `contains`, `in` (with `[...]` lists) and the connectives `and`, `or`, `not`, grouped with parentheses:

```bash
tatr ls -f '(:status eq OPEN)'
tatr ls -f ':tags contains feature'
tatr ls -f '(:status eq OPEN) and (:tags contains feature)'
tatr ls -f ':tags contains v0.8.0' --sort priority
```

Filtering composes with `-s/--sort` and `-R` (applied per section in recursive mode). Prefer `-f` over piping `tatr ls` through `grep`.

## Task File Format

Keep the metadata header exact; tatr owns it:

```markdown
# Task Title

- STATUS: OPEN
- PRIORITY: 100
- TAGS: feature, security

<free-form description body>
```

Status values are case-sensitive: `OPEN`, `IN_PROGRESS`, `CLOSED`. Priority is a non-negative integer, higher = more important - slot it RELATIVE to the existing list (`tatr ls --sort priority` first), not on an absolute scale. Projects may define scheduling-tag conventions in their AGENTS.md (e.g. every task carries `backlog` or the current release tag); check before tagging.

For any non-trivial task, structure the body as a story:

```markdown
## Story

As a <who>, I want <what>, so that <why>. Plus the context a cold
session needs to start.

## Steps

- [ ] Concrete, verifiable actions; /work ticks these as they land.

## Definition of Done

- Observable outcomes; the review contract. Each item names its proof:
  `(test: <name>)`, `(cmd: <command>)`, or `(manual: <what the user
  confirms>)` - see the plan skill. An item with no nameable proof is
  rephrased until observable or demoted to Notes.

## Notes

- Constraints, file pointers, `Depends on: <task-id>`, sequencing.
```

Trivial tasks may use a plain paragraph. Prefer `tatr edit` for the metadata fields and `tatr new -b` for the initial body; hand-edit the file only for later body updates.

The task's folder is also the home for its sibling records: `SPIKE.md` (/spike), `REVIEW.md` (/review), `RETRO.md` (/compound), `GOAL.md` (a /flow umbrella task's goal artifact - goal, done-definition, live task list), `NOTES.md` (design/fix record) - all next to TASK.md, never loose in docs/.

## Workflow

**Picking up work:**
1. `tatr ls --sort priority` (or with `-f '(:status eq OPEN)'`) to see the backlog.
2. `tatr show <id>` to read the full task, then `tatr edit <id> -s IN_PROGRESS` to claim it.
3. Append implementation notes to the description as you go.

**Finishing work:**
1. `tatr edit <id> -s CLOSED`.
2. In the description, record what changed and why, difficulties or bugs hit along the way, and brief self-reflection on what could have gone better. Future sessions read this.
3. Commit the TASK.md change together with the code changes.

**Planning a feature:**
- Break it into multiple tasks with `tatr new`, one per component, with priorities that encode the intended order.
- Use consistent tags within the project (`feature`, `bug`, `refactor`, `testing`, `docs`, `security`, `performance`), plus the project's scheduling tags if it defines them.
- Create tasks for any non-trivial follow-up work discovered mid-session instead of leaving TODO comments in code.

**With worktrees:** when the work will happen in a sprout worktree, sprout FIRST and run `tatr new` inside the worktree, so the task file is born on the branch. A task stub unavoidably created in the shared main checkout gets carried in as the first act after sprouting: copy it into the worktree, `rm` it from the main checkout.

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
- IDs are second-resolution. Since tatr 0.2.0 a same-second `tatr new` FAILS with "already exists" instead of silently overwriting (the old behavior lost tasks seven recorded times); on that error, retry once the second has passed. Still run one `tatr new` per command rather than chaining several - the chain would just fail midway.
