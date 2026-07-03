{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "sprout";
      runtimeInputs = [pkgs.git pkgs.fzf pkgs.tmux];
      text =
        /*
        bash
        */
        ''
          set +o errexit
          set +o pipefail
          set +o nounset

          usage() {
              echo "Usage: sprout [-i|--interactive] [COMMAND] [ARGS]"
              echo "Manage git worktrees so several agents can work a repo in parallel."
              echo
              echo "Commands:"
              echo "  new <feature>    Create a worktree and branch for <feature>, off HEAD"
              echo "  ls               List this project's worktrees"
              echo "  show <feature>   Print the path to <feature>'s worktree"
              echo "  rm <feature>     Remove <feature>'s worktree, branch and tmux session"
              echo "  help             Show this help message"
              echo
              echo "Options:"
              echo "  -i, --interactive  Open a tmux session on the worktree: 'new' drops"
              echo "                     you into the new worktree's session; 'ls' fzf-picks"
              echo "                     an existing worktree and switches to its session."
              echo
              echo "Worktrees live under \$XDG_CACHE_HOME/sprouts/<project>/<feature>"
              echo "(\$HOME/.cache/sprouts/... by default), where <project> is the repo"
              echo "directory name."
          }

          # Resolve the project from the MAIN worktree so sprout behaves the
          # same whether it is run from the main checkout or from inside one of
          # its own worktrees (where 'git rev-parse --show-toplevel' would point
          # at the worktree, not the repo). The first entry of 'git worktree
          # list' is always the main worktree.
          main_worktree=$(git worktree list --porcelain 2> /dev/null | awk '/^worktree /{print substr($0, 10); exit}')
          if [[ -z $main_worktree ]]; then
              echo "sprout: not inside a git repository" >&2
              exit 1
          fi
          project=$(basename "$main_worktree")

          cache_home=''${XDG_CACHE_HOME:-$HOME/.cache}
          sprouts_root="$cache_home/sprouts/$project"

          worktree_path() {
              # $1: feature name -> prints its worktree path
              echo "$sprouts_root/$1"
          }

          require_feature() {
              # $1: feature name. Fails (non-zero, message on stderr) if the name
              # is missing or would escape the sprouts root / be an unsafe branch.
              case "$1" in
                  "")
                      echo "sprout: missing <feature>" >&2
                      return 1
                      ;;
                  -* | /*)
                      echo "sprout: invalid feature name '$1' (must not start with '-' or '/')" >&2
                      return 1
                      ;;
                  .. | ../* | */.. | */../*)
                      echo "sprout: invalid feature name '$1' (must not contain '..')" >&2
                      return 1
                      ;;
              esac
              return 0
          }

          session_name() {
              # $1: feature -> prints the tmux session name, namespaced by
              # project so a 'main' feature in two repos does not collide. tmux
              # forbids '.' and ':' in names, so fold '.', '/' and space to '_'.
              echo "$project"_"$1" | tr './ :' '____'
          }

          open_session() {
              # $1: worktree path  $2: feature name. Opens or switches to the
              # worktree's tmux session, mirroring tmux-sessionizer (sesh).
              wt=$1
              name=$(session_name "$2")

              # new-session -ds also starts the server if none is running, so no
              # separate pgrep check is needed.
              if ! tmux has-session -t "=$name" 2> /dev/null; then
                  if ! tmux new-session -ds "$name" -c "$wt"; then
                      echo "sprout: failed to create tmux session '$name'" >&2
                      exit 1
                  fi
              fi

              if [[ -z $TMUX ]]; then
                  tmux attach -t "=$name"
              else
                  tmux switch-client -t "=$name"
              fi
          }

          cmd_new() {
              feature=$1
              require_feature "$feature" || exit 1

              path=$(worktree_path "$feature")
              if [[ -e $path ]]; then
                  echo "sprout: worktree already exists at $path" >&2
                  exit 1
              fi

              mkdir -p "$(dirname "$path")"

              # Reuse the branch if it already exists, otherwise create it off HEAD.
              # git's progress chatter goes to stderr so stdout is only the path,
              # which lets callers do: cd "$(sprout new feat)". Fail loudly if the
              # worktree could not be created rather than reporting a bogus path.
              if git show-ref --verify --quiet "refs/heads/$feature"; then
                  git worktree add "$path" "$feature" 1>&2
              else
                  git worktree add -b "$feature" "$path" HEAD 1>&2
              fi

              if [[ ! -d $path ]]; then
                  echo "sprout: failed to create worktree for '$feature'" >&2
                  exit 1
              fi

              echo "$path"
          }

          cmd_ls() {
              # Show only worktrees that sprout created (those under sprouts_root).
              git worktree list --porcelain | awk -v root="$sprouts_root/" '
                  function emit() {
                      if (wt != "" && index(wt, root) == 1) {
                          feat = substr(wt, length(root) + 1)
                          printf "%-20s %-28s %s\n", feat, branch, wt
                      }
                  }
                  /^worktree / { emit(); wt = substr($0, 10); branch = "-" }
                  /^branch /   { branch = substr($0, 8); sub("refs/heads/", "", branch) }
                  END          { emit() }
              '
          }

          cmd_ls_interactive() {
              # fzf-pick a worktree from the ls table and open its session.
              line=$(cmd_ls | fzf --with-nth=1,2)
              if [[ -z $line ]]; then
                  echo "sprout: nothing selected" >&2
                  exit 1
              fi
              feature=$(echo "$line" | awk '{print $1}')
              open_session "$(worktree_path "$feature")" "$feature"
          }

          cmd_show() {
              feature=$1
              require_feature "$feature" || exit 1

              path=$(worktree_path "$feature")
              if [[ ! -d $path ]]; then
                  echo "sprout: no worktree for '$feature' at $path" >&2
                  exit 1
              fi
              echo "$path"
          }

          cmd_rm() {
              feature=$1
              require_feature "$feature" || exit 1

              path=$(worktree_path "$feature")
              removed=false

              if git worktree list --porcelain | grep -qx "worktree $path"; then
                  git worktree remove "$path" || git worktree remove --force "$path"
                  removed=true

                  # Drop now-empty parent dirs left by slash-named features
                  # (e.g. .../sprouts/<project>/feature/), stopping at the root.
                  parent=$(dirname "$path")
                  while [[ $parent == "$sprouts_root"/* ]]; do
                      rmdir "$parent" 2> /dev/null || break
                      parent=$(dirname "$parent")
                  done
              else
                  echo "sprout: no worktree at $path" >&2
              fi

              # Delete the branch from the main repo; warn if it is already gone.
              if git show-ref --verify --quiet "refs/heads/$feature"; then
                  git branch -D "$feature"
                  removed=true
              else
                  echo "sprout: branch '$feature' already gone" >&2
              fi

              # Tear down the tmux session for this worktree, if any exists.
              tmux kill-session -t "=$(session_name "$feature")" 2> /dev/null || true

              # Nothing matched at all: report failure rather than a silent no-op.
              if [[ $removed == false ]]; then
                  echo "sprout: nothing to remove for '$feature'" >&2
                  exit 1
              fi
          }

          # A leading -i/--interactive gates the tmux behavior of new and ls.
          interactive=false
          case "''${1:-}" in
              -i | --interactive)
                  interactive=true
                  shift
                  ;;
          esac

          cmd=''${1:-}
          if [[ $# -gt 0 ]]; then
              shift
          fi

          case "$cmd" in
              new)
                  cmd_new "$@"
                  if [[ $interactive == true ]]; then
                      open_session "$(worktree_path "$1")" "$1"
                  fi
                  ;;
              ls)
                  if [[ $interactive == true ]]; then
                      cmd_ls_interactive
                  else
                      cmd_ls
                  fi
                  ;;
              show)            cmd_show "$@" ;;
              rm)              cmd_rm "$@" ;;
              help | -h | --help) usage ;;
              "")              usage ;;
              *)
                  echo "sprout: unknown command '$cmd'" >&2
                  usage
                  exit 1
                  ;;
          esac
        '';
    })
  ];
}
