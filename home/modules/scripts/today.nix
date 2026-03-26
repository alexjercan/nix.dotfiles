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
                echo "Open the daily journal entry for today."
                echo
                echo "  -t, --template  Use a template for the journal entry."
                echo "  -h, --help      Display this help and exit."
                echo
                echo " DEN-PATH        The path to the den directory."
                echo
                echo "If DEN-PATH is not provided, the default path will be used."
                echo "The default path is: $THE_DEN_PATH"
                echo "The default template is: $DEFAULT_TEMPLATE"
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

                if [[ ! -f "$YESTERDAY_FILE" ]]; then
                  echo "Warning: $YESTERDAY_FILE not found" >&2
                  exit 1
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
                    cp "$DEN_PATH/Templates/$TEMPLATE" "$1"
                    templator "$1"
                else
                    echo "# $(date +%A), $(date +%B) $(date +%d), $(date +%Y)" > "$1"
                fi
            }

            # Parse options
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -t|--template)
                        shift
                        TEMPLATE="$1"
                        ;;
                    -h|--help)
                        usage
                        exit 0
                        ;;
                    *)
                        DEN_PATH="$1"
                        DEN_PATH="$${DEN_PATH%/}"
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

            # If file does not exits create it
            if [[ ! -f "$FILE" ]]; then
                create "$FILE"
            fi

            edit "$FILE"
          '';
      })
    ];
  };
}
