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
      description = "Enable my `daily` Bash script.";
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
            NOTE_MODE=0
            NOTE_TAG=""
            WEIGHT_MODE=0
            MACROS_ENTRY_MODE=0
            MACROS_ENTRY_TEXT=""

            usage() {
                echo "Usage: $0 [DEN-PATH] [OPTIONS]"
                echo "Show the daily statistics for the journal."
                echo
                echo "  -n, --note <TAG>      Show notes with the specified tag (note :: <TAG>)."
                echo "  -w, --weight          Show weight for the journal."
                echo "  -m, --macros-entry    Add text entry to the Macros section."
                echo "  -N, --offset <N>      The number of days to offset from today."
                echo "  -h, --help            Display this help and exit."
                echo
                echo " DEN-PATH               The path to the den directory."
                echo
                echo "If DEN-PATH is not provided, the default path will be used."
                echo "The default path is: $THE_DEN_PATH"
                echo "The default offset is: $DEFAULT_OFFSET"
            }

            # Parse options
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -n|--note)
                        shift
                        if [[ -z "$1" || "$1" == -* ]]; then
                            echo "Error: --note requires a tag argument."
                            usage
                            exit 1
                        fi
                        NOTE_MODE=1
                        NOTE_TAG="$1"
                        ;;
                    -w|--weight)
                        WEIGHT_MODE=1
                        ;;
                    -m|--macros-entry)
                        shift
                        if [[ -z "$1" ]]; then
                            echo "Error: --macros-entry requires a text argument."
                            usage
                            exit 1
                        fi
                        MACROS_ENTRY_MODE=1
                        MACROS_ENTRY_TEXT="$1"
                        ;;
                    -N|--offset)
                        shift
                        if [[ -z "$1" || "$1" == -* ]]; then
                            echo "Error: --offset requires a numeric argument."
                            usage
                            exit 1
                        fi
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

            run_note() {
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
            }

            run_weight() {
                echo "date,weight" > /tmp/weight_data.csv
                last=0
                find "$DEN_PATH/Daily" -type f -name "*.md" | sort | while read -r file; do
                    filename=$(basename "$file")
                    date_part=$(echo "$filename" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}')

                    weight=$(grep -Po 'weight :: \K[0-9]+\.?[0-9]*(?= Kg)' "$file" || true)

                    if [[ -z "$weight" ]]; then
                      weight=$last
                    fi
                    last=$weight

                    echo "$date_part,$weight"
                done >> /tmp/weight_data.csv

                echo "CSV written to /tmp/weight_data.csv"
                echo "Generating plot..."

                # https://gnuplot.sourceforge.net/demo/running_avg.html
                ${pkgs.gnuplot}/bin/gnuplot -e "
                  set datafile separator ',';
                  set terminal pngcairo size 1000,600 enhanced font 'Source Code Pro,12';
                  set output '/tmp/weight_plot.png';
                  set title 'Weight Over Time';
                  set xlabel 'Date';
                  set xdata time;
                  set timefmt '%Y-%m-%d';
                  set format x '%Y-%m-%d';
                  set xtics rotate by -45;
                  set ylabel 'Weight (Kg)';
                  set grid ytics xtics;
                  set key top left;

                  back1 = back2 = back3 = back4 = back5 = 0;
                  count = 0;

                  shift5(x) = (back5 = back4, back4 = back3, back3 = back2, back2 = back1, back1 = x, count = count + 1);
                  avg5(x) = (shift5(x), (count < 5) ? NaN : (back1 + back2 + back3 + back4 + back5) / 5);

                  set style line 1 lw 1.5 lc rgb 'green';
                  set style line 2 lw 2   lc rgb 'orange';

                  plot '/tmp/weight_data.csv' using 1:2 title 'Weight' with lines ls 1, \
                       '/tmp/weight_data.csv' using 1:(avg5(\$2)) title '5-day rolling avg' with lines ls 2
                "

                echo "Plot saved to /tmp/weight_plot.png"
                echo "feh /tmp/weight_plot.png"
            }

            add_macros_entry() {
                # Add an entry to the Macros section
                # $1: The file to modify
                # $2: The text to add
                local file="$1"
                local text="$2"
                
                # Use awk to find the Macros section and append the text
                awk -v text="$text" '
                    BEGIN { in_macros = 0; blank_count = 0; }
                    
                    # Detect the start of the Macros section
                    /^### 🍽️ Macros/ {
                        in_macros = 1;
                        print;
                        next;
                    }
                    
                    # When in macros section
                    in_macros {
                        # If we hit another header, insert text before the buffered blank lines
                        if (/^###/) {
                            print text;
                            for (i = 0; i < blank_count; i++) print "";
                            in_macros = 0;
                            print;
                            next;
                        }
                        # If blank line, increment counter
                        if (/^$/) {
                            blank_count++;
                            next;
                        }
                        # Non-blank line: print any buffered blank lines, then this line
                        if (blank_count > 0) {
                            for (i = 0; i < blank_count; i++) print "";
                            blank_count = 0;
                        }
                        print;
                        next;
                    }
                    
                    # Print all other lines
                    { print; }
                    
                    # If we reached EOF while still in Macros section, append text
                    END {
                        if (in_macros) {
                            print text;
                            for (i = 0; i < blank_count; i++) print "";
                        }
                    }
                ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
                
                echo "Added entry to Macros section in $file"
            }

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

            today_tasks() {
                awk '
                  /^Today$/ { flag=1; next }
                  flag && /^- \[[ x]\] / { print; next }
                  flag { flag=0 }
                ' "$FILE"
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
                if (index($0, ",") == 0) next;
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

            run_daily() {
                title
                echo
                echo "### 🌱 Habits"
                echo
                habits
                echo
                echo "### 📝 Today's Tasks"
                echo
                today_tasks
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

            # Main function
            {
                if [[ $NOTE_MODE -eq 1 ]]; then
                    run_note
                elif [[ $WEIGHT_MODE -eq 1 ]]; then
                    run_weight
                elif [[ $MACROS_ENTRY_MODE -eq 1 ]]; then
                    DATE=$(date -d "-$OFFSET days" +%Y-%m-%d-%A)
                    FILE="$DEN_PATH/Daily/$DATE.md"

                    if [[ ! -f "$FILE" ]]; then
                        echo "No daily journal entry found for $DATE."
                        exit 1
                    fi

                    add_macros_entry "$FILE" "$MACROS_ENTRY_TEXT"
                else
                    DATE=$(date -d "-$OFFSET days" +%Y-%m-%d-%A)
                    FILE="$DEN_PATH/Daily/$DATE.md"

                    if [[ ! -f "$FILE" ]]; then
                        echo "No daily journal entry found for $DATE."
                        exit 1
                    fi

                    run_daily
                fi
            }
          '';
      })
    ];
  };
}
