{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.weight = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable my `weight` Bash script.";
    };

    rootPath = mkOption {
      type = types.str;
      default = "/default/path";
      description = "The root path used by the script.";
    };
  };

  config = mkIf config.weight.enable {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "weight";
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

            usage() {
                echo "Usage: $0 [DEN-PATH] [OPTIONS]"
                echo "Show the daily statistics for the journal."
                echo
                echo "  -h, --help      Display this help and exit."
                echo
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
                        DEN_PATH="$1"
                        DEN_PATH="$${DEN_PATH%/}"
                        ;;
                esac
                shift
            done

            if [[ -z "$DEN_PATH" ]]; then
                DEN_PATH="$THE_DEN_PATH"
            fi

            # Main output
            {
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
          '';
      })
    ];
  };
}
