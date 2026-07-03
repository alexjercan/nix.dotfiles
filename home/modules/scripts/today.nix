{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.today = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable my `today` Bash script.";
    };

    rootPath = mkOption {
      type = types.str;
      default = "/default/path";
      description = "The root path used by the script.";
    };

    defaultTemplate = mkOption {
      type = types.str;
      default = "daily.md";
      description = "The default template used by the script.";
    };
  };

  config = mkIf config.today.enable {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "today";
        runtimeInputs = [];
        text =
          /*
          bash
          */
          ''
            set +o errexit
            set +o pipefail
            set +o nounset

            THE_DEN_PATH=${config.today.rootPath}
            DEFAULT_TEMPLATE=${config.today.defaultTemplate}
            DEFAULT_EDITOR="nvim"

            usage() {
                echo "Usage: $0 [DEN-PATH] [OPTIONS]"
                echo "Open (or create) today's daily journal entry."
                echo
                echo "  -t, --template  Use a template for the journal entry."
                echo "  -c, --create    Create the entry if missing, do not open the"
                echo "                  editor, and print its path to stdout."
                echo "  -p, --path      Print the path to today's entry to stdout"
                echo "                  WITHOUT creating it. Does not open the editor."
                echo "  -h, --help      Display this help and exit."
                echo
                echo " DEN-PATH        The path to the den directory."
                echo
                echo "If DEN-PATH is not provided, the default path will be used."
                echo "The default path is: $THE_DEN_PATH"
                echo "The default template is: $DEFAULT_TEMPLATE"
                echo
                echo "Exit codes: 0 success, 1 runtime error (e.g. missing template),"
                echo "2 usage error (unknown option). With --create/--path the only"
                echo "thing written to stdout is the entry path, so it composes:"
                echo "  file=\$($0 --create)"
            }

            templator() {
                # Applies the template replacements to the file
                # $1: The file to apply the template to

                # Replace {{title}}
                sed -i "s/{{title}}/$(date +%A), $(date +%B) $(date +%d), $(date +%Y)/" "$1"

                # Find the `Tomorrow` section which contains a list `-` in yesterday's entry
                # and copy it to today's entry
                # The format is
                # ```markdown
                # Tomorrow
                # - Task 1
                # - Task 2
                # ```
                YESTERDAY=$(date -d "yesterday" "$DATE_FORMAT")
                YESTERDAY_FILE="$DAILY_PATH/$YESTERDAY.md"
                TARGET_FILE="$1"

                # A missing yesterday file is normal (e.g. the first entry ever,
                # or a gap in the journal): warn and skip the carry-over instead
                # of aborting, so creating today's entry still succeeds.
                if [[ ! -f "$YESTERDAY_FILE" ]]; then
                  echo "Warning: $YESTERDAY_FILE not found, skipping carry-over" >&2
                  return 0
                fi

                grep -Pzo "Tomorrow\n(- .*\n)+" "$YESTERDAY_FILE" | \
                  tr '\0' '\n' | \
                  sed -E '
                    1s/^Tomorrow/Today/;
                    s/^- (.*)/- [ ] \1/
                  ' >> "$TARGET_FILE"
            }

            edit() {
                # Open the file in the editor
                # $1: The file to open
                $EDITOR "$1"
            }

            create() {
                # Create a new journal entry
                # $1: The file to create
                if [[ -n "$TEMPLATE" ]]; then
                    if [[ ! -f "$DEN_PATH/Templates/$TEMPLATE" ]]; then
                        echo "Error: template not found: $DEN_PATH/Templates/$TEMPLATE" >&2
                        exit 1
                    fi
                    cp "$DEN_PATH/Templates/$TEMPLATE" "$1"
                    templator "$1"
                else
                    echo "# $(date +%A), $(date +%B) $(date +%d), $(date +%Y)" > "$1"
                fi
            }

            # Parse options
            CREATE_ONLY=false
            PATH_ONLY=false
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -t|--template)
                        shift
                        TEMPLATE="$1"
                        ;;
                    -c|--create)
                        CREATE_ONLY=true
                        ;;
                    -p|--path)
                        PATH_ONLY=true
                        ;;
                    -h|--help)
                        usage
                        exit 0
                        ;;
                    -*)
                        echo "Error: unknown option: $1" >&2
                        usage >&2
                        exit 2
                        ;;
                    *)
                        DEN_PATH="$1"
                        DEN_PATH="''${DEN_PATH%/}"
                        ;;
                esac
                shift
            done

            # Check if DEN_PATH is set
            if [[ -z "$DEN_PATH" ]]; then
                DEN_PATH="$THE_DEN_PATH"
            fi

            # Check if the template is set
            if [[ -z "$TEMPLATE" ]]; then
                TEMPLATE="$DEFAULT_TEMPLATE"
            fi

            # Create a new journal entry
            DATE_FORMAT="+%Y-%m-%d-%A"
            DATE=$(date "$DATE_FORMAT")
            DAILY_PATH="$DEN_PATH/Daily"
            FILE="$DAILY_PATH/$DATE.md"


            # Set the editor to neovim if not set
            if [[ -z "$EDITOR" ]]; then
                EDITOR="$DEFAULT_EDITOR"
            fi

            # --path: report where today's entry lives without creating anything.
            if [[ "$PATH_ONLY" == true ]]; then
                echo "$FILE"
                exit 0
            fi

            # If file does not exist create it
            if [[ ! -f "$FILE" ]]; then
                create "$FILE"
            fi

            # --create: non-interactive. Print the entry path (and only that) so
            # the command composes, and do not open the editor.
            if [[ "$CREATE_ONLY" == true ]]; then
                echo "$FILE"
                exit 0
            fi

            # Interactive default: open the entry in the editor.
            edit "$FILE"
          '';
      })
    ];
  };
}
