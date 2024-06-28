{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "sesh";
      runtimeInputs = [pkgs.tmux];
      text =
        /*
        bash
        */
        ''
          set +o errexit
          set +o pipefail

          usage() {
              echo "Usage: tmux-sessionizer [--help | -h] [--open | -o <directory>] [directory...]"
              echo "  --help, -h: Show this help message"
              echo "  --open, -o: Open a directory in a new tmux session"
              echo "  --create, -c: Create a new project in your projects folder"
              echo "  directory:  Search in the provided directories for a session to open"
              echo "  If no directory is provided, the script will search for directories in ~/personal and ~/work"
          }

          if [[ $# -eq 1 && ($1 == "--help" || $1 == "-h") ]]; then
              usage
              exit 0
          fi

          if [[ $# -eq 1 && ($1 == "--create" || $1 == "-c") ]]; then
              echo "Error: --create requires a directory" >&2
              usage
              exit 1
          fi

          if [[ $# -eq 1 && ($1 == "--open" || $1 == "-o") ]]; then
              echo "Error: --open requires a directory" >&2
              usage
              exit 1
          fi

          selected=

          if [[ $# -eq 0 ]]; then
              selected=$(find ~/personal ~/work -mindepth 1 -maxdepth 1 -type d | fzf)
          elif [[ $# -eq 2 && $1 == "--open" || $1 == "-o" ]]; then
              selected=$2
          elif [[ $# -eq 2 && $1 == "--create" || $1 == "-c" ]]; then
              selected=~/personal/$2
              mkdir -p "$selected"
          else
              selected=$(find "$@" -mindepth 1 -maxdepth 1 -type d | fzf)
          fi

          if [[ -z $selected ]]; then
              echo "Nothing was selected"
              exit 1
          fi

          selected_name=$(basename "$selected" | tr . _)
          tmux_running=$(pgrep tmux)

          if [[ -z $tmux_running ]]; then
              tmux new-session -s "$selected_name" -c "$selected"
          else
              if ! tmux has-session -t="$selected_name" 2> /dev/null; then
                  tmux new-session -ds "$selected_name" -c "$selected"
              fi

              if [[ -z $TMUX ]]; then
                  tmux attach -t "$selected_name"
              else
                  tmux switch-client -t "$selected_name"
              fi
          fi
        '';
    })
  ];
}
