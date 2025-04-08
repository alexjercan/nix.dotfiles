{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.daily = {
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
  };

  config = mkIf config.daily.enable {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "daily";
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
            DEFAULT_OFFSET=0

            usage() {
                echo "Usage: $0 [DEN-PATH] [OPTIONS]"
                echo "Show the daily statistics for the journal."
                echo
                echo "  -n, --offset    The number of days to offset from today."
                echo "  -h, --help      Display this help and exit."
                echo
                echo " DEN-PATH        The path to the den directory."
                echo
                echo "If DEN-PATH is not provided, the default path will be used."
                echo "The default path is: $THE_DEN_PATH"
                echo "The default offset is: $DEFAULT_OFFSET"
            }

            # Parse options
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -n|--offset)
                        shift
                        OFFSET="$1"
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

            if [[ -z "$DEN_PATH" ]]; then
                DEN_PATH="$THE_DEN_PATH"
            fi

            if [[ -z "$OFFSET" ]]; then
                OFFSET=$DEFAULT_OFFSET
            fi

            DATE=$(date -d "-$OFFSET days" +%Y-%m-%d-%A)
            FILE="$DEN_PATH/Daily/$DATE.md"

            if [[ ! -f "$FILE" ]]; then
                echo "No daily journal entry found for $DATE."
                exit 1
            fi

            # Get title (first line)
            title() {
              echo "# $(head -n 1 "$FILE" | sed 's/# //')"
            }

            # Get weight
            weight() {
              grep -oE 'weight :: [0-9]+(\.[0-9]+)? Kg' "$FILE" | \
                sed -E 's/.* ([0-9]+(\.[0-9]+)?) Kg/**Weight**: \1 Kg/' || \
                echo "**Weight**: nan Kg"
            }

            # Get habits
            habits() {
              awk "/### 🌱 Habits/ {flag=1; next} /###/ {flag=0} flag" "$FILE" | tail -n +2 | head -n -1
            }

            # Get macros
            macros() {
              awk "/### 🍽️ Macros/ {flag=1; next} /###/ {flag=0} flag" "$FILE" | tail -n +2 | head -n -1 > /tmp/macros.csv

              if [ ! -s /tmp/macros.csv ]; then
                echo "**Total Macros**: 0g protein, 0g carbs, 0g fat"
                echo "**Total Calories**: 0 calories"
                return
              fi

              header=$(head -n 1 /tmp/macros.csv)
              protein_col=$(echo "$header" | tr ',' '\n' | grep -n 'protein' | cut -d: -f1)
              carbs_col=$(echo "$header" | tr ',' '\n' | grep -n 'carbs' | cut -d: -f1)
              fat_col=$(echo "$header" | tr ',' '\n' | grep -n 'fat' | cut -d: -f1)

              tail -n +2 /tmp/macros.csv | awk -F, -v p="$protein_col" -v c="$carbs_col" -v f="$fat_col" '
              {
                protein += $p;
                carbs += $c;
                fat += $f;
              }
              END {
                calories = protein * 4 + carbs * 4 + fat * 9;
                printf "**Total Macros**: %.2fg protein, %.2fg carbs, %.2fg fat\n", protein, carbs, fat;
                printf "**Total Calories**: %.0f calories\n", calories;
              }'
            }

            # Main output
            {
              title
              echo
              echo "### 🌱 Habits"
              echo
              habits
              echo
              echo "### 🍽️Macros"
              echo
              macros
              echo
              echo "### 🏋️ Weight"
              echo
              weight
              echo
            }
          '';
      })
    ];
  };
}
