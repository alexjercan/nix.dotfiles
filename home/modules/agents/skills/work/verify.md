# Verification

Read this at work step 5, before closing out. Do not report success on the
strength of the diff; the checks must actually pass, and if some fail, say so
with the output.

## What to run

1. The repository's canonical check suite - its AGENTS.md `## Agent workflow`
   cache names it. Tests, linter, formatter, type checker, build.
2. Every proof from `tatr proofs <id>`, executed verbatim. Confirm each passes
   on ITS OWN criterion, not a neighbouring one.
3. `tatr check <id>`, and `tatr check --ledger <ledger>` when the repo has a
   lessons ledger.

A `manual:` proof is not yours to tick. Report it as pending user confirmation
and leave it for the reviewer to list and the user to accept. Self-ticking a
manual item is the proxy verification the notation exists to prevent.

## Every verification must be able to fail

If a check would still pass with the mechanism deleted, it proves nothing.
Replace it with one that can fail.

## Pitfalls that have shipped breakage

- **Never pipe a check through a filter that eats its exit code.**
  `cargo test | grep ...` reports grep's 0 on a failed compile. Run it bare,
  or write the output to a file and grep the file, or `set -o pipefail`.
- **Shared systems need the whole suite.** When the change touches a shared
  observer, or adds to a shared schedule chain, run the whole affected
  module's suite. Only the EXISTING tests catch a silently broken consumer.
- **New required fields break what a plain check never compiles.** Exhaustive
  constructors in tests and examples fail late. Build all targets (e.g.
  `cargo check --all-targets`) and grep the repo for the type's literal.
- **Fixture pins live far from the diff.** Before landing a content or data
  change, grep for tests that assert on or `include_str!` the exact files
  touched. Pin durable intents, not frozen literals a sibling will move.
- **Sabotage-test in the right order.** To prove a regression test really
  pins the bug, COMMIT the fix first, then sabotage, then
  `git checkout <file>` to restore. A file-level checkout against an
  uncommitted tree has destroyed finished work.

## The doc-surface sweep

For every command, flag, type, path or behavior the diff renames, removes or
changes, grep the repository's doc surfaces and fix every stale mention in the
same task: README, the reference docs, AGENTS.md (its module maps and version
claims especially), and the skill files when the repo ships skills.

Stale docs are not cosmetic - an outdated AGENTS.md module map has made a
session invent API names a reviewer then had to catch.

**Task history is immutable.** The `tasks/` tree is the append-only record of
what was true when each task ran, not a doc surface to correct. EXCLUDE it
from the sweep (`--exclude-dir=tasks`, or scope the grep to code and doc
paths) and never rewrite an old TASK/REVIEW/RETRO/NOTES to match a later
rename. This is why absence-proving DoD greps also exclude `tasks/`: the
record legitimately still quotes the old name. Fix the live doc surfaces;
leave the history verbatim.

## Before removing a mechanism

Grep the workspace for its symbol names, its describing WORDS, and everything
that observes or queries it - including comments, docs, examples, tests and
the changelog. Silent consumers outlive clean symbol sweeps.

## Syncing with the default branch

A branch cannot land until it is up to date with its base. Merge the local
default branch INTO the feature branch inside the worktree, resolve conflicts
there, commit the merge, then re-run this whole verification. The branch is
ready only when it is green and
`git merge-base --is-ancestor <default> <branch>` succeeds. `work` never
merges into the default branch; that is the caller's step.
