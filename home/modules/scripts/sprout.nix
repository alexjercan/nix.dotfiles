{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "sprout";
      runtimeInputs = [pkgs.git pkgs.fzf];
      text =
        /*
        bash
        */
        ''
          set +o errexit
          set +o pipefail
          set +o nounset

          usage() {
              echo "Usage: sprout [COMMAND] [ARGS]"
              echo "Manage git worktrees so several agents can work a repo in parallel."
              echo
              echo "Commands:"
              echo "  new <feature>    Create a worktree and branch for <feature>, off HEAD"
              echo "  ls               List this project's worktrees"
              echo "  show <feature>   Print the path to <feature>'s worktree"
              echo "  rm <feature>     Remove <feature>'s worktree and branch"
              echo "  help             Show this help message"
              echo
              echo "Worktrees live under \$XDG_CACHE_HOME/sprouts/<project>/<feature>"
              echo "(\$HOME/.cache/sprouts/... by default), where <project> is the repo"
              echo "directory name."
          }

          # Resolve the repository root; every command needs to run inside a repo.
          repo_root=$(git rev-parse --show-toplevel 2> /dev/null)
          if [[ -z $repo_root ]]; then
              echo "sprout: not inside a git repository" >&2
              exit 1
          fi
          project=$(basename "$repo_root")

          cache_home=''${XDG_CACHE_HOME:-$HOME/.cache}
          sprouts_root="$cache_home/sprouts/$project"

          worktree_path() {
              # $1: feature name -> prints its worktree path
              echo "$sprouts_root/$1"
          }

          cmd_new() {
              feature=$1
              if [[ -z $feature ]]; then
                  echo "sprout new: missing <feature>" >&2
                  usage
                  exit 1
              fi

              path=$(worktree_path "$feature")
              if [[ -e $path ]]; then
                  echo "sprout: worktree already exists at $path" >&2
                  exit 1
              fi

              mkdir -p "$sprouts_root"

              # Reuse the branch if it already exists, otherwise create it off HEAD.
              # git's progress chatter goes to stderr so stdout is only the path,
              # which lets callers do: cd "$(sprout new feat)".
              if git show-ref --verify --quiet "refs/heads/$feature"; then
                  git worktree add "$path" "$feature" 1>&2
              else
                  git worktree add -b "$feature" "$path" HEAD 1>&2
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

          cmd_show() {
              feature=$1
              if [[ -z $feature ]]; then
                  echo "sprout show: missing <feature>" >&2
                  exit 1
              fi

              path=$(worktree_path "$feature")
              if [[ ! -d $path ]]; then
                  echo "sprout: no worktree for '$feature' at $path" >&2
                  exit 1
              fi
              echo "$path"
          }

          cmd_rm() {
              feature=$1
              if [[ -z $feature ]]; then
                  echo "sprout rm: missing <feature>" >&2
                  exit 1
              fi

              path=$(worktree_path "$feature")
              removed=false

              if git worktree list --porcelain | grep -qx "worktree $path"; then
                  git worktree remove "$path" || git worktree remove --force "$path"
                  removed=true
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

              # Nothing matched at all: report failure rather than a silent no-op.
              if [[ $removed == false ]]; then
                  echo "sprout: nothing to remove for '$feature'" >&2
                  exit 1
              fi
          }

          cmd=''${1:-}
          if [[ $# -gt 0 ]]; then
              shift
          fi

          case "$cmd" in
              new)             cmd_new "$@" ;;
              ls)              cmd_ls "$@" ;;
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
