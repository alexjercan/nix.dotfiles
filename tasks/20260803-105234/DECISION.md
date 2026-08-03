# Decision: Add sprout sync and land --dry-run, remember the target branch, and have compound write the landing message

- DATE: 20260803-110859
- STATUS: ACCEPTED
- TASK: 20260803-105234
- TAGS: sprout, skills, landing

## Context

Two load-bearing forks fall out of `tasks/20260803-105234/NOTES.md`.

**1. What `land` does when `sprout.target` and the main checkout's branch
disagree.** `cmd_land` squash-merges by running `git merge --squash <feature>`
inside the MAIN worktree, so the commit lands on whatever branch that checkout
has checked out - that is what the command means, not a parameter sprout
chooses. Recording `sprout.target` at `new` therefore cannot redirect where a
land goes; it can only be compared against where the land is about to go.

**2. Where the landing message lives.** `compound` must record a landing commit
message so a script can call `sprout land -m` without reading the diff. `tatr`'s
record kinds are a fixed enum in its source (TASK, SPIKE, DECISION, REVIEW,
RETRO); a new kind is an upstream change to a tool outside this repository.
Verified in scratch: a RETRO.md with an extra `## Landing message` section
passes `tatr check` (rc=0), so extra sections are legal today.

## Decision

**1. `land` refuses a `sprout.target` / main-checkout mismatch**, naming both
branches and telling the caller to check out the target. `resolve_target`
prefers the worktree-local `sprout.target`, falling back to the main checkout's
`symbolic-ref` when absent. `sprout.target` thus makes the previously implicit
"you are landing onto whatever main has checked out" assumption explicit and
checkable, rather than changing where anything lands.

Built from scratch under today's constraints this is still the shape: the only
alternative that redirects the land is checking the target branch out inside
sprout, which turns an atomic command into one that mutates the shared main
checkout's HEAD.

**2. The landing message lives in `RETRO.md`, in a fenced `## Landing message`
section** after `## Action items`: subject line, blank line, body, so `awk` can
lift it. `compound` already owns RETRO.md, already has the whole task in
context, and already runs immediately before the LAND_READY gate.

## Alternatives considered

- **`land` lands onto `sprout.target` regardless of main's HEAD.** Would check
  ancestry against one branch and commit onto another, or require sprout to
  check out a branch in the shared main checkout. Rejected: silently wrong in
  the first form, and non-atomic in the second.
- **`land` ignores the mismatch (pure fallback, no guard).** Cheapest, and the
  status quo. Rejected: then `sprout.target` is recorded and never read by
  `land`, which buys nothing over the existing derivation.
- **A new `LANDING` tatr record kind.** Cleanest separation, and a schema that
  could validate the message shape. Rejected: the kinds are a fixed enum in
  `tatr.c`, which is not in this repository; this task would grow an upstream
  dependency for a section that already validates.
- **A new reference file under `compound/`.** Rejected: `check.sh`'s reference
  graph requires every reference be reachable from a `## Load on demand`
  pointer, which costs body words too - the same budget the instruction is
  competing for, plus a file.
- **Do nothing; keep writing the message at land time.** Costs the afk runner
  the ability to land without a diff-reading session, which is the point of the
  task.

## Consequences

Easier: a runner can drive `sync -n` / `sync` / `land -n` / `land -m` with no
judgement; the target a branch was cut from survives the session that cut it; a
land onto the wrong branch is now caught by a message instead of by a bad
commit.

Harder: `compound` gains an obligation inside a 400-word body budget it already
sits at 390 words against, so existing prose pays for it. Existing worktrees
have no `sprout.target`, so the new guard cannot fire for them - the fallback
keeps them working but silently unprotected. Recording `sprout.target` makes
every `sprout new` write `extensions.worktreeConfig` at repo level, a config
write on a path that was previously read-only for plain `new`; it is the same
idempotent write `--task` already performs. And the mismatch guard turns a
previously-succeeding land (target checked out differs from where the branch was
cut) into a refusal - intended, but it is a behaviour change, not only an
addition.
