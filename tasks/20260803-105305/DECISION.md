# Decision: Let afk own the gate transitions, the record commits and the landing

- DATE: 20260803-124500
- STATUS: ACCEPTED
- TASK: 20260803-105305
- TAGS: afk, scripts, agents

## Context

`tasks/20260803-105305/NOTES.md` leaves four forks open once the gate sessions
are replaced by probes.

**1. The record commit message.** The three lifecycle gates run `tatr flow`
and then have to commit `tasks/<id>`, because `sprout land` refuses a dirty
main checkout and the phase session no longer commits anything. TASK.md says
"a mechanical message (`docs: advance <id> to PLANNING`) or something better"
and leaves it there.

**2. Who commits the records at `LAND_READY`.** That gate performs no `tatr`
transition; `compound` already ran the close itself. So it is not obvious
whether afk should commit there at all.

**3. How `afk.nix` reaches sprout.** afk now shells out to `sprout`, which is
not a `pkgs` attribute: the `writeShellApplication` is inline in
`home/modules/scripts/sprout.nix`, a home-manager module, and a module's
`home.packages` entry cannot be referenced from another module.

**4. Whether to re-verify between `sprout sync` and `sprout land`.**
`landing.md` step 2 tells a human-driven flow to re-run the repository's checks
on the merged branch. TASK.md says afk skips it.

## Decision

**1. `advance` reads the activity back from tatr for the message.** It commits
with `docs: advance <id> to $(task_activity <id>)`, evaluated AFTER the
`tatr flow` call.

**2. afk owns the record commit at all four gates, and refuses a worktree that
is still dirty afterwards.** The `LAND_READY` arm runs
`commit_records <root> <id> "docs: close <id>"` before the sync, then dies if
`git status --porcelain` in the worktree is non-empty.

**3. The sprout derivation moves to `home/modules/scripts/sprout-pkg.nix`,** a
function of `pkgs` returning the `writeShellApplication`. `sprout.nix` installs
it into `home.packages`; `afk.nix` adds the same import to `runtimeInputs`.

**4. No re-verification between sync and land.**

## Alternatives considered

**1.** A caller-supplied constant per gate, or the task title. The constant is
wrong for the PLAN gate, whose postcondition value is a gate name (`PLAN`)
while the cursor lands in `WORKING` - the message would name a gate, or need a
second target parameter that exists only for the commit subject. The title
duplicates what the record says one line down, and goes stale if the title is
edited mid-task. Reading the activity back needs no parameter, is always
truthful, and survives an overshoot: a session that ran on to REVIEWING gets a
commit that says REVIEWING.

**2.** Leave `LAND_READY` alone and trust `compound` to have committed. The
failure is silent and irreversible: an uncommitted RETRO.md or TASK.md is
squashed away, landing a record that still reads COMPOUNDING with no retro.
`sprout sync` does not catch it - `git merge` on an already-up-to-date target
succeeds whatever the working tree looks like. Committing there costs one call
and makes exactly one place in afk responsible for records; the cleanliness
check is what that uniformity buys, because after the record commit any
remaining dirt is implementation work that would be dropped.

**3.** An overlay exporting `sprout` as a `pkgs` attribute. That adds a global
name, and a rebuild surface for the whole configuration, for a dependency with
two consumers in one directory. Copying the derivation into `afk.nix` was the
other option and is a second copy of the runtime inputs to keep in step.

**4.** Run the repository's canonical checks on the merged branch before
landing. That doubles a run's wall clock for a signal the next `afk run`
surfaces anyway, and afk has no way to know what "canonical" means for an
arbitrary repository without new configuration.

## Consequences

- The commit subject at a gate names wherever the cursor actually ended up, so
  an overshooting session produces a commit that skips a phase name. That is
  the honest reading, not a bug to fix later.
- `commit_records` must be a no-op when nothing was staged: `compound` still
  commits its own retro, so the `LAND_READY` call usually stages nothing.
- afk can now refuse a land that a human-driven flow would have completed - a
  worktree with uncommitted implementation files. The remedy is in the
  worktree, and the run is resumable with `afk run <task-id>`.
- `sprout.nix` and `afk.nix` both break if `sprout-pkg.nix` changes shape;
  `nix flake check` covers that, and `writeShellApplication` still shellchecks
  `sprout.sh` at build time.
- A branch that goes red only after merging its landing target lands red. The
  user checks the default branch after a run, which is where that shows up.
  Revisit if a parallel-landed task ever breaks a synced branch in practice.
