# Add sprout git-worktree CLI core (new/ls/show/rm)

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: feature

## Goal

Add a `sprout` CLI, packaged as a Nix `writeShellApplication` in
`home/modules/scripts/`, that manages git worktrees and branches so multiple
agents can work the same repo in parallel without colliding. This task
delivers the worktree lifecycle (create, list, show, remove); tmux
integration is layered on in the follow-up task.

## Steps

- [x] Create `home/modules/scripts/sprout.nix` following the plain-module
      style of `home/modules/tmux/tmux-sessionizer.nix` (a `{pkgs, ...}:`
      module with a single `writeShellApplication` named `sprout`, no options
      block). Set `runtimeInputs = [pkgs.git pkgs.fzf]` (fzf reserved for the
      next task; git is needed now).
- [x] Import the new file from `home/modules/scripts/default.nix` alongside
      `./today.nix` and `./daily.nix`.
- [x] In the script, resolve the repo root with `git rev-parse --show-toplevel`
      and derive `project = basename` of it. Fail with a clear message if not
      inside a git repo.
- [x] Compute the sprouts root as
      `${XDG_CACHE_HOME:-$HOME/.cache}/sprouts/<project>`; the worktree path
      for a feature is `<root>/<feature>`.
- [x] Implement `sprout new <feature>`: create the branch and worktree off the
      current `HEAD` with `git worktree add -b <feature> <path> HEAD`
      (mkdir -p the parent root first). If the branch already exists, add the
      worktree without `-b`. Print the resulting path on success. (Session
      opening is added in the tmux task.)
- [x] Implement `sprout ls`: list this project's worktrees. Prefer parsing
      `git worktree list --porcelain` and showing only those under the
      sprouts root, printing `<feature>  <branch>  <path>` per line.
- [x] Implement `sprout show <feature>`: print just the absolute worktree path
      (so `cd "$(sprout show feat)"` works), erroring if it does not exist.
- [x] Implement `sprout rm <feature>`: `git worktree remove` the path (with
      `--force` fallback if dirty is acceptable) and delete the `<feature>`
      branch with `git branch -D`. Warn but do not hard-fail if the branch is
      already gone. (Killing the tmux session is added in the tmux task.)
- [x] Add a `usage()`/`--help`/`-h` handler and dispatch on the first arg
      (`new|ls|show|rm|help`); an unknown subcommand prints usage to stderr and
      exits non-zero.
- [x] Verify the module evaluates: `nix build .#homeConfigurations... ` is
      heavy, so instead run `nix eval` / `home-manager build --flake .#alex`
      if available, or at minimum `nix flake check`-free sanity by building
      just the package. Confirm `sprout --help`, `new`, `ls`, `show`, `rm`
      work end to end in a scratch git repo.
- [x] Document the tool and the design decisions (worktree location, branch
      strategy) in `docs/` per the repo convention.

## Notes

- Relevant files: `home/modules/tmux/tmux-sessionizer.nix` (style reference,
  `set +o errexit/pipefail/nounset`, `writeShellApplication`, escaping `$$`
  and `$${...}` inside the Nix string), `home/modules/scripts/default.nix`
  (imports today+daily), `home/modules/scripts/today.nix` (options-module
  style, not used here), `home/alex/default.nix:250` (imports the scripts
  module).
- The scripts module is imported as `"${modulesPath}/scripts"`, which loads
  `home/modules/scripts/default.nix`; new files must be imported there.
- Nix string escaping: inside the `''...''` block, shell `$VAR` must be
  written `$VAR` only if not ambiguous; use `$${VAR}` for literal shell
  `${VAR}` and `''${...}` where needed. Mirror how today.nix escapes
  `$${DEN_PATH%/}`.
- Branch off `HEAD` (current branch) by default; keep it simple, no base-ref
  flag for now.
- Design decision to record: worktrees live in a central hidden cache root
  `~/.cache/sprouts/<project>/<feature>` (user preference) rather than inside
  the repo, so repo scans and tooling never descend into them.

## Record

**What changed.** Added `home/modules/scripts/sprout.nix` (a plain
`{pkgs, ...}` module with one `writeShellApplication` named `sprout`,
`runtimeInputs = [git fzf]`), imported it from
`home/modules/scripts/default.nix`, and documented the tool and its design
decisions in `docs/sprout.md`. The script implements `new`, `ls`, `show`,
`rm`, and `help`, resolving the repo with `git rev-parse --show-toplevel` and
placing worktrees under `${XDG_CACHE_HOME:-$HOME/.cache}/sprouts/<project>`.

**Decisions / alternatives.** Followed the tmux-sessionizer style of using
brace-free `$VAR` shell references so the Nix indented string needs almost no
escaping (only `''${XDG_CACHE_HOME:-...}` and `''${1:-}` use the `''${...}`
escape). Chose the central cache root over sibling/in-repo layouts (see
docs/sprout.md). `new` and `ls` reuse an existing branch rather than failing.

**Difficulties / bugs found during self-testing.**
- `git worktree add` prints "HEAD is now at ..." to *stdout*, which polluted
  `$(sprout new feat)`. Fixed by redirecting git's output to stderr (`1>&2`)
  so stdout carries only the worktree path.
- `sprout rm` of a feature with neither a worktree nor a branch silently
  exited 0. Added a `removed` flag so a total no-op exits non-zero, while a
  partial cleanup (branch already gone) still succeeds.
- Verified by building just the package via the flake's nixpkgs
  (`nix build --impure --expr '... head (import ./sprout.nix ...).home.packages'`),
  which runs shellcheck, then exercising new/ls/show/rm plus error paths
  (missing args, unknown command, outside-repo, dirty-worktree force-remove)
  in a scratch git repo. A full `home-manager build` was not run; the isolated
  package build is sufficient to validate this module.

**Self-reflection.** The two bugs both came from not checking git's exact
stdout/stderr contract up front; testing the scripting use case
(`$(...)` capture) early is what surfaced them. Next time, decide a command's
stdout contract before writing it. Deferred all tmux/fzf behavior to the
follow-up task as planned, so the core stays independently useful (prints
paths) even without a tmux session.
