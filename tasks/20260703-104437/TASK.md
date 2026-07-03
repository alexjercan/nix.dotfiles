# Add sprout git-worktree CLI core (new/ls/show/rm)

- STATUS: OPEN
- PRIORITY: 100
- TAGS: feature

## Goal

Add a `sprout` CLI, packaged as a Nix `writeShellApplication` in
`home/modules/scripts/`, that manages git worktrees and branches so multiple
agents can work the same repo in parallel without colliding. This task
delivers the worktree lifecycle (create, list, show, remove); tmux
integration is layered on in the follow-up task.

## Steps

- [ ] Create `home/modules/scripts/sprout.nix` following the plain-module
      style of `home/modules/tmux/tmux-sessionizer.nix` (a `{pkgs, ...}:`
      module with a single `writeShellApplication` named `sprout`, no options
      block). Set `runtimeInputs = [pkgs.git pkgs.fzf]` (fzf reserved for the
      next task; git is needed now).
- [ ] Import the new file from `home/modules/scripts/default.nix` alongside
      `./today.nix` and `./daily.nix`.
- [ ] In the script, resolve the repo root with `git rev-parse --show-toplevel`
      and derive `project = basename` of it. Fail with a clear message if not
      inside a git repo.
- [ ] Compute the sprouts root as
      `${XDG_CACHE_HOME:-$HOME/.cache}/sprouts/<project>`; the worktree path
      for a feature is `<root>/<feature>`.
- [ ] Implement `sprout new <feature>`: create the branch and worktree off the
      current `HEAD` with `git worktree add -b <feature> <path> HEAD`
      (mkdir -p the parent root first). If the branch already exists, add the
      worktree without `-b`. Print the resulting path on success. (Session
      opening is added in the tmux task.)
- [ ] Implement `sprout ls`: list this project's worktrees. Prefer parsing
      `git worktree list --porcelain` and showing only those under the
      sprouts root, printing `<feature>  <branch>  <path>` per line.
- [ ] Implement `sprout show <feature>`: print just the absolute worktree path
      (so `cd "$(sprout show feat)"` works), erroring if it does not exist.
- [ ] Implement `sprout rm <feature>`: `git worktree remove` the path (with
      `--force` fallback if dirty is acceptable) and delete the `<feature>`
      branch with `git branch -D`. Warn but do not hard-fail if the branch is
      already gone. (Killing the tmux session is added in the tmux task.)
- [ ] Add a `usage()`/`--help`/`-h` handler and dispatch on the first arg
      (`new|ls|show|rm|help`); an unknown subcommand prints usage to stderr and
      exits non-zero.
- [ ] Verify the module evaluates: `nix build .#homeConfigurations... ` is
      heavy, so instead run `nix eval` / `home-manager build --flake .#alex`
      if available, or at minimum `nix flake check`-free sanity by building
      just the package. Confirm `sprout --help`, `new`, `ls`, `show`, `rm`
      work end to end in a scratch git repo.
- [ ] Document the tool and the design decisions (worktree location, branch
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
