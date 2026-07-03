# sprout - git worktrees for parallel agent work

`sprout` is a small CLI (a Nix `writeShellApplication` in
`home/modules/scripts/sprout.nix`) that manages git worktrees and branches so
several agents can work the same repository in parallel without stepping on
each other. Each feature gets its own worktree and branch, checked out in an
isolated directory outside the repo.

## Commands

```
sprout new <feature>    Create a worktree + branch <feature> off HEAD
sprout ls               List this project's worktrees
sprout show <feature>   Print the path to <feature>'s worktree
sprout rm <feature>     Remove <feature>'s worktree and branch
sprout help             Show usage
```

`sprout show` prints only the path, so it composes:
`cd "$(sprout show feat)"`. `sprout new` does the same on success (git's own
progress text is sent to stderr), so `cd "$(sprout new feat)"` works too.

## Where worktrees live

Worktrees are created under:

```
${XDG_CACHE_HOME:-$HOME/.cache}/sprouts/<project>/<feature>
```

where `<project>` is the basename of the repo root (`git rev-parse
--show-toplevel`). For example, feature `login` in `~/personal/nix.dotfiles`
lands at `~/.cache/sprouts/nix.dotfiles/login`.

### Why a central hidden cache root

The alternatives considered were a sibling directory per repo
(`<repo>.sprouts/`), a hidden directory inside the repo (`<repo>/.sprouts/`),
and this central cache root. The cache root was chosen because:

- It keeps the worktrees completely out of the repo tree, so repo scans,
  `find`, editors, and other tooling never descend into a parallel checkout.
- Grouping every project's worktrees under one predictable `~/.cache/sprouts`
  location makes them easy to find and clean up, and `~/.cache` is already the
  conventional home for regenerable, disposable state.

Branches are created off the current `HEAD` (whatever branch you are on when
you run `sprout new`). There is deliberately no base-ref flag yet; keep it
simple until a real need appears.

## Design notes

- Styled after `home/modules/tmux/tmux-sessionizer.nix`: `set +o
  errexit/pipefail/nounset`, a plain `{pkgs, ...}` module with a single
  `writeShellApplication`, and brace-free `$VAR` shell references to avoid
  Nix indented-string antiquotation (literal `${...}` would need `''${...}`).
- `ls` parses `git worktree list --porcelain` and shows only worktrees under
  the sprouts root, so unrelated worktrees you created by hand are not listed.
- `rm` uses `git worktree remove`, falling back to `--force` when the worktree
  is dirty, then deletes the branch with `git branch -D`. It exits non-zero
  only when there was nothing at all to remove, and prunes any now-empty parent
  directories left by slash-named features (up to the sprouts root).
- Feature names are validated (`require_feature`): a name may not be empty,
  start with `-` or `/`, or contain a `..` segment, so it cannot escape the
  sprouts root or be mistaken for a flag. Slashes are allowed
  (`sprout new feature/login` works).
- `new` only prints the worktree path and succeeds if `git worktree add`
  actually created it; a failed add exits non-zero with no path on stdout.
