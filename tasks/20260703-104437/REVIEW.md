# Review: Add sprout git-worktree CLI core (new/ls/show/rm)

- TASK: 20260703-104437
- BRANCH: feature/sprout-core

## Round 1

- VERDICT: REQUEST_CHANGES

- [x] R1.1 (MAJOR) home/modules/scripts/sprout.nix (cmd_new) - `cmd_new`
  ignores the exit status of `git worktree add`. With `errexit` off, when the
  add fails (invalid branch name, branch already checked out in another
  worktree, path conflict) the function still runs `echo "$path"` and returns
  0. Confirmed: `sprout new ../escape` prints
  `.../sprouts/rev/../escape` and exits 0 while creating nothing, so a caller
  doing `cd "$(sprout new x)"` lands in a non-existent directory and believes
  it succeeded. This defeats the tool's contract in exactly the parallel-agent
  scenario it exists for. Capture the result and fail loudly, e.g.:
  `if ! git worktree add ... 1>&2; then echo "sprout: failed to create worktree for '$feature'" >&2; exit 1; fi` (for both the reuse and the `-b` branch), and only `echo "$path"` on success.
  - Response: fixed. `cmd_new` now checks `[[ -d $path ]]` after the add and
    exits 1 with "failed to create worktree" if the worktree was not created,
    before any path is printed. Verified `sprout new ../escape` now exits 1
    and prints nothing on stdout.

- [x] R1.2 (MINOR) home/modules/scripts/sprout.nix (worktree_path / cmd_new) -
  the feature name is interpolated straight into the worktree path with no
  validation, so `..` segments and leading `/` produce paths outside
  `sprouts_root` (`sprout show ..` resolves to the parent of the root). Git
  happens to reject `..` as a branch name, but `show`/`rm` still dereference
  the traversed path. Add a guard that rejects an empty name, a name starting
  with `-`, `/`, or `.`, or containing a `..` segment, before building the
  path.
  - Response: fixed. Added a `require_feature` helper (rejects empty names,
    names starting with `-` or `/`, and any `..` segment) called by `new`,
    `show`, and `rm`. Verified `sprout show ..` and `sprout new -weird` both
    exit 1 with a clear message. (Leading `.` other than `..` is left allowed;
    only `..` traversal is unsafe.)

- [x] R1.3 (NIT) home/modules/scripts/sprout.nix (cmd_rm) - removing a
  slash-named feature (`feature/login`) leaves the now-empty intermediate
  directory (`.../sprouts/<project>/feature/`) behind. Optional: after a
  successful `git worktree remove`, `rmdir -p --ignore-fail-on-non-empty` the
  parent chain up to `sprouts_root`.
  - Response: fixed. After a successful `git worktree remove`, `rm` walks up
    from the worktree's parent calling `rmdir` (which only removes empty dirs),
    stopping at `sprouts_root`. Verified creating+removing `feature/login`
    leaves no empty `feature/` dir behind.

### Notes for context

- Verified positively: the module builds and passes shellcheck (via the
  flake-nixpkgs `nix build --impure --expr` package build); `new`, `ls`,
  `show`, `rm`, `help` all work end to end; slash feature names
  (`feature/login`) create, list, show, and remove correctly; `rm` of a
  fully-absent feature exits non-zero; `new`/`show` stdout is a single clean
  path suitable for `cd "$(...)"`; running outside a git repo errors cleanly.
- No automated tests exist for the scripts module (today/daily have none), so
  the manual end-to-end coverage matches repo conventions; not a finding.
- Docs (docs/sprout.md) and TASK.md notes accurately match the implementation.

## Round 2

- VERDICT: APPROVE

All three round-1 findings verified resolved in commit b0409de:
- R1.1: `sprout new ../escape` now exits 1 and prints no path; `cmd_new`
  asserts `[[ -d $path ]]` after the add.
- R1.2: `require_feature` rejects empty / `-*` / `/*` / `..`-segment names;
  confirmed `show ..` and `new -weird` exit 1.
- R1.3: the parent-prune loop is correctly bounded by `"$sprouts_root"/*`, so
  it never runs for non-slash features and never climbs above the root;
  confirmed `feature/login` create+remove leaves no empty dir.
Package still builds and passes shellcheck. No new issues introduced.
