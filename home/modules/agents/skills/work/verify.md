# Verification

Run, do not infer from the diff:

1. Canonical checks from AGENTS.md: tests, lint, format, types, build.
2. Every `tatr -r <task-root> proofs <id>` proof, independently against its
   criterion.
3. `tatr -r <task-root> check <id>`.

Leave `manual:` pending for user confirmation. Replace any check that stays
green with its mechanism removed.

## Failure traps

- Preserve exit codes: run bare, redirect then inspect, or use
  `set -o pipefail`.
- Shared observers/schedules require the whole affected suite.
- New required fields require all-target builds and a constructor sweep.
- Search tests for assertions/includes of changed data files; pin intent, not
  incidental literals.
- Commit before each sabotage; restore with `git checkout HEAD -- <file>`.

## Doc sweep

For every changed command, flag, type, path, or behavior, search live README,
docs, AGENTS.md, and shipped skills. Fix stale surfaces in this task.

Exclude `tasks/`: task history is append-only evidence, not current docs.
Before removing a mechanism, search symbols, describing words, and all
observers/queries across code, comments, docs, examples, tests, and changelog.

## Sync base

Before landing, merge the landing target into the feature inside its worktree,
resolve/commit there, then rerun all verification:

```bash
sprout sync <feature> -n   # probe: which paths would conflict
sprout sync <feature>
```

`work` never merges the feature into default.
