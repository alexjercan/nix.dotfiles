{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.note = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable my `note` Bash script.";
    };

    rootPath = mkOption {
      type = types.str;
      default = "/default/path";
      description = "The root path used by the script.";
    };
  };

  config = mkIf config.note.enable {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "note";
        runtimeInputs = [];
        text =
          /*
          bash
          */
          ''
            set +o errexit
            set +o pipefail
            set +o nounset

            THE_DEN_PATH=${config.daily.rootPath}
            NOTE_TAG=""

            usage() {
                echo "Usage: $0 <TAG> [DEN-PATH] [OPTIONS]"
                echo "Show the notes for the journal."
                echo
                echo "  -h, --help      Display this help and exit."
                echo
                echo " TAG             The tag to filter notes by."
                echo " DEN-PATH        The path to the den directory."
                echo
                echo "If DEN-PATH is not provided, the default path will be used."
                echo "The default path is: $THE_DEN_PATH"
            }

            # Parse options
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -h|--help)
                        usage
                        exit 0
                        ;;
                    *)
                        if [[ -z "$NOTE_TAG" ]]; then
                            NOTE_TAG="$1"
                        else
                            DEN_PATH="$1"
                            DEN_PATH="$${DEN_PATH%/}"
                        fi
                        ;;
                esac
                shift
            done

            if [[ -z "$NOTE_TAG" ]]; then
                echo "Error: TAG is required."
                usage
                exit 1
            fi

            if [[ -z "$DEN_PATH" ]]; then
                DEN_PATH="$THE_DEN_PATH"
            fi

            find "$DEN_PATH/Daily" -type f -name '*.md' | sort | while read -r file; do
                awk -v tag="$NOTE_TAG" -v file="$file" '
                    $0 ~ "note :: " tag {
                        print "" file ":" NR ""
                        while (getline nextline) {
                            if (nextline ~ /^[[:space:]]*$/) continue
                                print nextline
                                    break
                        }
                        while (getline nextline) {
                            if (nextline ~ /^$/) break
                            print nextline
                        }
                        print ""
                    }
                ' "$file"
            done
          '';
      })
    ];
  };
}
