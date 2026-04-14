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
            NOTES_ENTRY_MODE=0
            NOTES_ENTRY_TEXT=""
            TOGGLE_HABIT_MODE=0
            TOGGLE_HABIT_NAME=""
            TASK_ENTRY_MODE=0
            TASK_ENTRY_TEXT=""
            TASK_TOMORROW_ENTRY_MODE=0
            TASK_TOMORROW_ENTRY_TEXT=""
            TASK_REMOVE_MODE=0
            TASK_REMOVE_INDEX=""
            TASK_TOMORROW_REMOVE_MODE=0
            TASK_TOMORROW_REMOVE_INDEX=""
            TOGGLE_TASK_MODE=0
            TOGGLE_TASK_INDEX=""
            WEIGHT_ENTRY_MODE=0
            WEIGHT_ENTRY_VALUE=""

            usage() {
                echo "Usage: $0 [DEN-PATH] [OPTIONS]"
                echo "Show the daily statistics for the journal."
                echo
                echo "  -n, --note <TAG>                   Show notes with the specified tag (note :: <TAG>)."
                echo "  -w, --weight                       Show weight for the journal."
                echo "  --weight-entry <VALUE>             Log weight for the day (format: VALUE or VALUEKg)."
                echo "  -m, --macros-entry <TEXT>          Add text entry to the Macros section."
                echo "  -e, --notes-entry <TEXT>           Add text entry to the Notes section."
                echo "  --toggle-habit <HABIT>             Toggle habit checkbox completion."
                echo "  --task-entry <TEXT>                Add task to Today's Tasks section."
                echo "  --task-remove <INDEX>              Remove task from Today's Tasks by index."
                echo "  --task-tomorrow-entry <TEXT>       Add task to Tomorrow section."
                echo "  --task-tomorrow-remove <INDEX>     Remove task from Tomorrow section by index."
                echo "  --toggle-task <INDEX>              Toggle task completion by index."
                echo "  -N, --offset <N>                   The number of days to offset from today."
                echo "  -h, --help                         Display this help and exit."
                echo
                echo " DEN-PATH                            The path to the den directory."
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
                    --weight-entry)
                        shift
                        if [[ -z "$1" ]]; then
                            echo "Error: --weight-entry requires a value argument."
                            usage
                            exit 1
                        fi
                        WEIGHT_ENTRY_MODE=1
                        WEIGHT_ENTRY_VALUE="$1"
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
                    -e|--notes-entry)
                        shift
                        if [[ -z "$1" ]]; then
                            echo "Error: --notes-entry requires a text argument."
                            usage
                            exit 1
                        fi
                        NOTES_ENTRY_MODE=1
                        NOTES_ENTRY_TEXT="$1"
                        ;;
                    --toggle-habit)
                        shift
                        if [[ -z "$1" ]]; then
                            echo "Error: --toggle-habit requires a habit name argument."
                            usage
                            exit 1
                        fi
                        TOGGLE_HABIT_MODE=1
                        TOGGLE_HABIT_NAME="$1"
                        ;;
                    --task-entry)
                        shift
                        if [[ -z "$1" ]]; then
                            echo "Error: --task-entry requires a text argument."
                            usage
                            exit 1
                        fi
                        TASK_ENTRY_MODE=1
                        TASK_ENTRY_TEXT="$1"
                        ;;
                    --task-remove)
                        shift
                        if [[ -z "$1" ]]; then
                            echo "Error: --task-remove requires an index argument."
                            usage
                            exit 1
                        fi
                        TASK_REMOVE_MODE=1
                        TASK_REMOVE_INDEX="$1"
                        ;;
                    --task-tomorrow-entry)
                        shift
                        if [[ -z "$1" ]]; then
                            echo "Error: --task-tomorrow-entry requires a text argument."
                            usage
                            exit 1
                        fi
                        TASK_TOMORROW_ENTRY_MODE=1
                        TASK_TOMORROW_ENTRY_TEXT="$1"
                        ;;
                    --task-tomorrow-remove)
                        shift
                        if [[ -z "$1" ]]; then
                            echo "Error: --task-tomorrow-remove requires an index argument."
                            usage
                            exit 1
                        fi
                        TASK_TOMORROW_REMOVE_MODE=1
                        TASK_TOMORROW_REMOVE_INDEX="$1"
                        ;;
                    --toggle-task)
                        shift
                        if [[ -z "$1" ]]; then
                            echo "Error: --toggle-task requires an index argument."
                            usage
                            exit 1
                        fi
                        TOGGLE_TASK_MODE=1
                        TOGGLE_TASK_INDEX="$1"
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

            add_notes_entry() {
                # Add an entry to the Notes section
                # $1: The file to modify
                # $2: The text to add
                local file="$1"
                local text="$2"

                # Use awk to find the Notes section and append the text with an extra newline before it
                awk -v text="$text" '
                    BEGIN { in_notes = 0; blank_count = 0; }

                    # Detect the start of the Notes section
                    /^### 📝 Notes/ {
                        in_notes = 1;
                        print;
                        next;
                    }

                    # When in notes section
                    in_notes {
                        # If we hit another header, insert blank line + text before the buffered blank lines
                        if (/^###/) {
                            print "";
                            print text;
                            for (i = 0; i < blank_count; i++) print "";
                            in_notes = 0;
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

                    # If we reached EOF while still in Notes section, append blank line + text
                    END {
                        if (in_notes) {
                            print "";
                            print text;
                            for (i = 0; i < blank_count; i++) print "";
                        }
                    }
                ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

                echo "Added entry to Notes section in $file"
            }

            toggle_habit() {
                # Toggle a habit checkbox
                # $1: The file to modify
                # $2: The habit name to toggle
                local file="$1"
                local habit_name="$2"

                # Use awk to find the habit and toggle its checkbox
                awk -v habit="$habit_name" '
                    BEGIN { in_habits = 0; found = 0; }

                    # Detect the start of the Habits section
                    /^### 🌱 Habits/ {
                        in_habits = 1;
                        print;
                        next;
                    }

                    # When in habits section
                    in_habits {
                        # If we hit another header, exit habits section
                        if (/^###/) {
                            in_habits = 0;
                            print;
                            next;
                        }
                        # Check if this line contains the habit
                        if (tolower($0) ~ tolower(habit)) {
                            found = 1;
                            # Toggle the checkbox
                            if ($0 ~ /- \[ \]/) {
                                gsub(/- \[ \]/, "- [x]");
                            } else if ($0 ~ /- \[x\]/) {
                                gsub(/- \[x\]/, "- [ ]");
                            }
                        }
                        print;
                        next;
                    }

                    # Print all other lines
                    { print; }
                ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

                echo "Toggled habit '$habit_name' in $file"
            }

            add_task_entry() {
                # Add a task to Today's Tasks section
                # $1: The file to modify
                # $2: The text to add
                local file="$1"
                local text="$2"

                # Use awk to find Today's Tasks and add a checkbox task
                awk -v text="- [ ] $text" '
                    BEGIN { in_today = 0; blank_count = 0; }

                    # Detect the "Today" header in the Tasks section
                    /^Today$/ {
                        in_today = 1;
                        print;
                        next;
                    }

                    # When in today section
                    in_today {
                        # If we hit another section marker or header, insert text before buffered blanks
                        if (/^###/ || /^Tomorrow$/) {
                            print text;
                            for (i = 0; i < blank_count; i++) print "";
                            in_today = 0;
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

                    # If we reached EOF while still in today section, append text
                    END {
                        if (in_today) {
                            print text;
                            for (i = 0; i < blank_count; i++) print "";
                        }
                    }
                ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

                echo "Added task to Today's Tasks in $file"
            }

            add_task_tomorrow_entry() {
                # Add a task to Tomorrow section
                # $1: The file to modify
                # $2: The text to add
                local file="$1"
                local text="$2"

                # Use awk to find Tomorrow section and add a bullet point (no checkbox)
                # If Tomorrow section doesn't exist, create it after Today section
                awk -v text="- $text" '
                    BEGIN { in_tomorrow = 0; in_today = 0; blank_count = 0; has_tomorrow = 0; }

                    # Detect the "Tomorrow" header
                    /^Tomorrow$/ {
                        has_tomorrow = 1;
                        in_tomorrow = 1;
                        in_today = 0;
                        # Print any buffered blank lines before Tomorrow
                        if (blank_count > 0) {
                            for (i = 0; i < blank_count; i++) print "";
                            blank_count = 0;
                        }
                        print;
                        next;
                    }

                    # Detect the "Today" header
                    /^Today$/ {
                        in_today = 1;
                        # Print any buffered blank lines before Today
                        if (blank_count > 0) {
                            for (i = 0; i < blank_count; i++) print "";
                            blank_count = 0;
                        }
                        print;
                        next;
                    }

                    # When in tomorrow section
                    in_tomorrow {
                        # If we hit a header, insert text before buffered blanks
                        if (/^###/) {
                            print text;
                            for (i = 0; i < blank_count; i++) print "";
                            in_tomorrow = 0;
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

                    # When in today section and Tomorrow doesnt exist yet
                    in_today && !has_tomorrow {
                        # If we hit another header, insert Tomorrow section before it
                        if (/^###/) {
                            # Insert Tomorrow section with the task
                            print "";
                            print "Tomorrow";
                            print text;
                            for (i = 0; i < blank_count; i++) print "";
                            has_tomorrow = 1;
                            in_today = 0;
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

                    # When not in a special section, handle blank lines
                    !in_tomorrow && !in_today {
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

                    # If we reached EOF
                    END {
                        if (in_tomorrow) {
                            # We were in Tomorrow section, just add the task
                            print text;
                            for (i = 0; i < blank_count; i++) print "";
                        } else if (!has_tomorrow) {
                            # Tomorrow section never existed, create it at the end
                            print "";
                            print "Tomorrow";
                            print text;
                        }
                    }
                ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

                echo "Added task to Tomorrow in $file"
            }

            toggle_task() {
                # Toggle a task checkbox by index
                # $1: The file to modify
                # $2: The task index (1-based)
                local file="$1"
                local index="$2"

                # Use awk to find the Nth task and toggle it
                awk -v idx="$index" '
                    BEGIN { in_today = 0; task_count = 0; }

                    # Detect the "Today" header
                    /^Today$/ {
                        in_today = 1;
                        print;
                        next;
                    }

                    # When in today section
                    in_today {
                        # If we hit another section or header, exit
                        if (/^###/ || /^Tomorrow$/) {
                            in_today = 0;
                            print;
                            next;
                        }
                        # If this is a task line
                        if (/^- \[[ x]\]/) {
                            task_count++;
                            # If this is the target task, toggle it
                            if (task_count == idx) {
                                if ($0 ~ /- \[ \]/) {
                                    gsub(/- \[ \]/, "- [x]");
                                } else if ($0 ~ /- \[x\]/) {
                                    gsub(/- \[x\]/, "- [ ]");
                                }
                            }
                        }
                        print;
                        next;
                    }

                    # Print all other lines
                    { print; }
                ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

                echo "Toggled task #$index in $file"
            }

            remove_task() {
                # Remove a task from Today section by index
                # $1: The file to modify
                # $2: The task index (1-based)
                local file="$1"
                local index="$2"

                # Use awk to find the Nth task and skip it
                awk -v idx="$index" '
                    BEGIN { in_today = 0; task_count = 0; }

                    # Detect the "Today" header
                    /^Today$/ {
                        in_today = 1;
                        print;
                        next;
                    }

                    # When in today section
                    in_today {
                        # If we hit another section or header, exit
                        if (/^###/ || /^Tomorrow$/) {
                            in_today = 0;
                            print;
                            next;
                        }
                        # If this is a task line
                        if (/^- \[[ x]\]/) {
                            task_count++;
                            # If this is the target task, skip it (dont print)
                            if (task_count == idx) {
                                next;
                            }
                        }
                        print;
                        next;
                    }

                    # Print all other lines
                    { print; }
                ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

                echo "Removed task #$index from Today in $file"
            }

            remove_task_tomorrow() {
                # Remove a task from Tomorrow section by index
                # $1: The file to modify
                # $2: The task index (1-based)
                local file="$1"
                local index="$2"

                # Use awk to find the Nth task in Tomorrow and skip it
                awk -v idx="$index" '
                    BEGIN { in_tomorrow = 0; task_count = 0; }

                    # Detect the "Tomorrow" header
                    /^Tomorrow$/ {
                        in_tomorrow = 1;
                        print;
                        next;
                    }

                    # When in tomorrow section
                    in_tomorrow {
                        # If we hit a header, exit tomorrow section
                        if (/^###/) {
                            in_tomorrow = 0;
                            print;
                            next;
                        }
                        # If this is a task line (bullet point)
                        if (/^- /) {
                            task_count++;
                            # If this is the target task, skip it (dont print)
                            if (task_count == idx) {
                                next;
                            }
                        }
                        print;
                        next;
                    }

                    # Print all other lines
                    { print; }
                ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

                echo "Removed task #$index from Tomorrow in $file"
            }

            add_weight_entry() {
                # Add or update weight entry in the Notes section
                # $1: The file to modify
                # $2: The weight value (e.g., "75" or "75Kg" or "75 Kg")
                local file="$1"
                local weight_value="$2"

                # Normalize the weight value - ensure it has decimal point and "Kg" unit
                # Remove any existing "Kg" or "kg" and whitespace
                weight_value=$(echo "$weight_value" | sed -E 's/[[:space:]]*(Kg|kg|KG)//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                
                # Add .0 if no decimal point exists
                if ! echo "$weight_value" | grep -q '\.'; then
                    weight_value="''${weight_value}.0"
                fi
                
                local weight_line="weight :: $weight_value Kg"

                # Use awk to find the Notes section and add/update the weight entry
                awk -v weight="$weight_line" '
                    BEGIN { in_notes = 0; has_weight = 0; blank_count = 0; prev_was_blank = 0; }

                    # Detect the start of the Notes section
                    /^### 📝 Notes/ {
                        in_notes = 1;
                        print;
                        next;
                    }

                    # When in notes section
                    in_notes {
                        # If we find an existing weight entry, update it and preserve blank before
                        if (/^weight :: /) {
                            # Ensure there is a blank line before weight
                            if (!prev_was_blank && blank_count == 0) {
                                print "";
                            }
                            # Print any buffered blank lines (should be just one)
                            for (i = 0; i < blank_count; i++) print "";
                            blank_count = 0;
                            print weight;
                            has_weight = 1;
                            prev_was_blank = 0;
                            next;
                        }
                        # If we hit another header
                        if (/^###/) {
                            # Add weight if not found yet
                            if (!has_weight) {
                                # Ensure blank line before weight
                                if (blank_count == 0) {
                                    print "";
                                }
                                print weight;
                            }
                            for (i = 0; i < blank_count; i++) print "";
                            in_notes = 0;
                            print;
                            next;
                        }
                        # If blank line, increment counter
                        if (/^$/) {
                            blank_count++;
                            next;
                        }
                        # Non-blank line
                        if (blank_count > 0) {
                            for (i = 0; i < blank_count; i++) print "";
                            prev_was_blank = 1;
                            blank_count = 0;
                        } else {
                            prev_was_blank = 0;
                        }
                        print;
                        next;
                    }

                    # Print all other lines
                    { print; }

                    # If we reached EOF while still in Notes section
                    END {
                        if (in_notes && !has_weight) {
                            # Ensure blank line before weight
                            if (blank_count == 0) {
                                print "";
                            }
                            print weight;
                            for (i = 0; i < blank_count; i++) print "";
                        }
                    }
                ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

                echo "Added/updated weight entry to $weight_value Kg in $file"
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
                elif [[ $NOTES_ENTRY_MODE -eq 1 ]]; then
                    DATE=$(date -d "-$OFFSET days" +%Y-%m-%d-%A)
                    FILE="$DEN_PATH/Daily/$DATE.md"

                    if [[ ! -f "$FILE" ]]; then
                        echo "No daily journal entry found for $DATE."
                        exit 1
                    fi

                    add_notes_entry "$FILE" "$NOTES_ENTRY_TEXT"
                elif [[ $TOGGLE_HABIT_MODE -eq 1 ]]; then
                    DATE=$(date -d "-$OFFSET days" +%Y-%m-%d-%A)
                    FILE="$DEN_PATH/Daily/$DATE.md"

                    if [[ ! -f "$FILE" ]]; then
                        echo "No daily journal entry found for $DATE."
                        exit 1
                    fi

                    toggle_habit "$FILE" "$TOGGLE_HABIT_NAME"
                elif [[ $TASK_ENTRY_MODE -eq 1 ]]; then
                    DATE=$(date -d "-$OFFSET days" +%Y-%m-%d-%A)
                    FILE="$DEN_PATH/Daily/$DATE.md"

                    if [[ ! -f "$FILE" ]]; then
                        echo "No daily journal entry found for $DATE."
                        exit 1
                    fi

                    add_task_entry "$FILE" "$TASK_ENTRY_TEXT"
                elif [[ $TASK_REMOVE_MODE -eq 1 ]]; then
                    DATE=$(date -d "-$OFFSET days" +%Y-%m-%d-%A)
                    FILE="$DEN_PATH/Daily/$DATE.md"

                    if [[ ! -f "$FILE" ]]; then
                        echo "No daily journal entry found for $DATE."
                        exit 1
                    fi

                    remove_task "$FILE" "$TASK_REMOVE_INDEX"
                elif [[ $TASK_TOMORROW_ENTRY_MODE -eq 1 ]]; then
                    DATE=$(date -d "-$OFFSET days" +%Y-%m-%d-%A)
                    FILE="$DEN_PATH/Daily/$DATE.md"

                    if [[ ! -f "$FILE" ]]; then
                        echo "No daily journal entry found for $DATE."
                        exit 1
                    fi

                    add_task_tomorrow_entry "$FILE" "$TASK_TOMORROW_ENTRY_TEXT"
                elif [[ $TASK_TOMORROW_REMOVE_MODE -eq 1 ]]; then
                    DATE=$(date -d "-$OFFSET days" +%Y-%m-%d-%A)
                    FILE="$DEN_PATH/Daily/$DATE.md"

                    if [[ ! -f "$FILE" ]]; then
                        echo "No daily journal entry found for $DATE."
                        exit 1
                    fi

                    remove_task_tomorrow "$FILE" "$TASK_TOMORROW_REMOVE_INDEX"
                elif [[ $TOGGLE_TASK_MODE -eq 1 ]]; then
                    DATE=$(date -d "-$OFFSET days" +%Y-%m-%d-%A)
                    FILE="$DEN_PATH/Daily/$DATE.md"

                    if [[ ! -f "$FILE" ]]; then
                        echo "No daily journal entry found for $DATE."
                        exit 1
                    fi

                    toggle_task "$FILE" "$TOGGLE_TASK_INDEX"
                elif [[ $WEIGHT_ENTRY_MODE -eq 1 ]]; then
                    DATE=$(date -d "-$OFFSET days" +%Y-%m-%d-%A)
                    FILE="$DEN_PATH/Daily/$DATE.md"

                    if [[ ! -f "$FILE" ]]; then
                        echo "No daily journal entry found for $DATE."
                        exit 1
                    fi

                    add_weight_entry "$FILE" "$WEIGHT_ENTRY_VALUE"
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
