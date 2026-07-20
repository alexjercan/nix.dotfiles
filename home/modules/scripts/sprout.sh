#!/usr/bin/env bash
# sprout - manage git worktrees so several agents can work a repo in parallel.
#
# This file is the whole implementation; sprout.nix wraps it with
# pkgs.writeShellApplication, which prepends its own strict-mode prologue
# (relaxed right below) and puts git, fzf and tmux on PATH. Keeping the script
# in a plain file makes it directly testable:
#   bash home/modules/scripts/sprout-test.sh

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
    echo "  land <feature> -m <subject> [-m <body>]"
    echo "                   Squash-merge <feature> into the main checkout's"
    echo "                   branch as one commit, then remove its worktree,"
    echo "                   branch and tmux session"
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

cache_home=${XDG_CACHE_HOME:-$HOME/.cache}
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

cmd_land() {
    # Land <feature> onto the main checkout's branch as ONE squash commit,
    # then clean up the worktree, branch and tmux session. The whole landing
    # runs inside a single process so no staged-but-uncommitted state is ever
    # left in the shared main checkout for a parallel session to sweep up.
    feature=$1
    shift
    require_feature "$feature" || exit 1

    path=$(worktree_path "$feature")
    if [[ ! -d $path ]]; then
        echo "sprout: no worktree for '$feature' at $path" >&2
        exit 1
    fi
    if ! git show-ref --verify --quiet "refs/heads/$feature"; then
        echo "sprout: no branch '$feature'" >&2
        exit 1
    fi

    # Removing a worktree from inside itself fails after the commit has
    # already landed; refuse up front instead of half-landing. Compare
    # resolved paths so a symlinked route into the worktree cannot evade it.
    real_pwd=$(realpath "$PWD" 2> /dev/null)
    real_path=$(realpath "$path" 2> /dev/null)
    case "$real_pwd/" in
        "$real_path"/*)
            echo "sprout: cannot land from inside the '$feature' worktree; run it from the main checkout" >&2
            exit 1
            ;;
    esac

    # Collect -m parts exactly like git commit; at least a subject is needed.
    msgs=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m)
                shift
                if [[ $# -eq 0 ]]; then
                    echo "sprout: -m requires a message" >&2
                    exit 1
                fi
                msgs+=(-m "$1")
                shift
                ;;
            *)
                echo "sprout: unexpected argument '$1' (usage: sprout land <feature> -m <subject> [-m <body>])" >&2
                exit 1
                ;;
        esac
    done
    if [[ ${#msgs[@]} -eq 0 ]]; then
        echo "sprout: land needs a commit message (-m <subject> [-m <body>])" >&2
        exit 1
    fi

    # The landing target is whatever branch the MAIN checkout has checked
    # out. Flow keeps that on the default branch; refuse the degenerate cases.
    target=$(git -C "$main_worktree" symbolic-ref --quiet --short HEAD)
    if [[ -z $target ]]; then
        echo "sprout: main checkout is on a detached HEAD; check out the target branch first" >&2
        exit 1
    fi
    if [[ $target == "$feature" ]]; then
        echo "sprout: main checkout has '$feature' itself checked out; nothing to land onto" >&2
        exit 1
    fi

    # Tracked files in the main checkout must be pristine so the landing
    # commit can only ever contain the squashed branch. Untracked files are
    # fine: they cannot end up in the commit, and a collision aborts the
    # squash below, which rolls back.
    if [[ -n $(git -C "$main_worktree" status --porcelain --untracked-files=no) ]]; then
        echo "sprout: main checkout has staged or modified files; commit or stash them before landing" >&2
        exit 1
    fi

    # The branch must already contain the target tip: syncing (and resolving
    # conflicts) happens on the branch, per the work skill. This also means
    # the squash below is a pure fast-forward of content and cannot conflict.
    if ! git -C "$main_worktree" merge-base --is-ancestor "$target" "$feature"; then
        echo "sprout: '$feature' is not up to date with '$target'; merge '$target' into it in the worktree, re-verify, then land" >&2
        exit 1
    fi

    # Squash and commit, rolling back to a clean tree on any failure (hook
    # failures, an empty squash, ...) so nothing staged is left behind.
    if ! git -C "$main_worktree" merge --squash "$feature" 1>&2; then
        git -C "$main_worktree" reset --merge 1>&2 || git -C "$main_worktree" reset --hard 1>&2
        echo "sprout: squash of '$feature' failed; main checkout reset" >&2
        exit 1
    fi
    if ! git -C "$main_worktree" commit --quiet "${msgs[@]}" 1>&2; then
        git -C "$main_worktree" reset --merge 1>&2 || git -C "$main_worktree" reset --hard 1>&2
        echo "sprout: commit failed (empty squash?); main checkout reset" >&2
        exit 1
    fi

    git -C "$main_worktree" log -1 --format='landed %h %s'

    # Cleanup chatter (git branch -D, worktree removal) goes to stderr so
    # stdout stays exactly the one 'landed ...' line, per the composability
    # convention.
    cmd_rm "$feature" 1>&2
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
case "${1:-}" in
    -i | --interactive)
        interactive=true
        shift
        ;;
esac

cmd=${1:-}
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
    land)            cmd_land "$@" ;;
    rm)              cmd_rm "$@" ;;
    help | -h | --help) usage ;;
    "")              usage ;;
    *)
        echo "sprout: unknown command '$cmd'" >&2
        usage
        exit 1
        ;;
esac
