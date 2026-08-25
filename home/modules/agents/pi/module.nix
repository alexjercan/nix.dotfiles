# Everything Pi lives under this directory: the options, the theme files, and
# one self-contained module per extension.
#
# Hand-rolled rather than pi.nix's Home Manager module. This repo only ever
# needed settings, themes and extensions, and the package now comes from the
# llm-agents overlay, which tracks upstream releases closely.
let
  # Extension modules are discovered from the directory names, so a new
  # extension needs no wiring outside its own folder. `pkgs` stays out of this
  # list: forcing a module argument while the imports are resolved recurses.
  entries = builtins.readDir ./extensions;
  extensionModules =
    map (name: ./extensions + "/${name}/module.nix")
    (builtins.filter (name: entries.${name} == "directory") (builtins.attrNames entries));
in
  {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.programs.agents;
    piCfg = cfg.pi;

    # Every module under pi/extensions/ declares `extensions.<name>.enable` and
    # `extensions.<name>.package`. Nothing here knows the individual names.
    enabledExtensions =
      lib.concatMap (ext: lib.optional ext.enable ext.package)
      (lib.attrValues piCfg.extensions);

    # themes/module.nix declares one `themes.<name>` per file in themes/.
    enabledThemes =
      lib.concatMap (theme: lib.optional theme.enable theme.source)
      (lib.attrValues piCfg.themes);

    pathFlags = flag: paths: lib.concatMap (path: [flag "${path}"]) paths;

    finalArgs =
      pathFlags "--extension" enabledExtensions
      ++ pathFlags "--theme" enabledThemes;

    declaredSettings = pkgs.writeText "pi-settings.json" (builtins.toJSON piCfg.settings);

    # pi rewrites settings.json itself - an in-app theme switch lands there - so
    # it must stay a real writable file. Merge the declared keys over what is on
    # disk and leave every other key alone.
    mergeSettings = pkgs.writeShellApplication {
      name = "pi-merge-settings";
      runtimeInputs = [pkgs.coreutils pkgs.jq];
      text = ''
        target="$1"
        declared="$2"

        mkdir -p "$(dirname "$target")"
        # A leftover store symlink from an earlier deployment is read-only.
        if [ -L "$target" ]; then
          rm "$target"
        fi

        tmp="$(mktemp "$target.XXXXXX")"
        # Both branches go through jq so a re-run compares equal and the
        # activation stays idempotent.
        if [ -f "$target" ]; then
          jq -s '.[0] * .[1]' "$target" "$declared" > "$tmp"
        else
          jq . "$declared" > "$tmp"
        fi
        chmod 0600 "$tmp"

        if [ -f "$target" ] && cmp -s "$tmp" "$target"; then
          rm "$tmp"
        else
          mv "$tmp" "$target"
        fi
      '';
    };

    wrapped =
      if finalArgs == []
      then piCfg.package
      else
        pkgs.writeShellScriptBin "pi" ''
          # These subcommands manage pi's own installed state and must not
          # inherit the declarative resource flags.
          case "''${1-}" in
            install | remove | uninstall | update | list | config)
              exec ${lib.escapeShellArg (lib.getExe piCfg.package)} "$@"
              ;;
            *)
              exec ${lib.escapeShellArg (lib.getExe piCfg.package)} ${lib.escapeShellArgs finalArgs} "$@"
              ;;
          esac
        '';
  in {
    imports = [./themes/module.nix] ++ extensionModules;

    options.programs.agents.pi = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether the agent workspace enables Pi.";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.llm-agents.pi;
        defaultText = lib.literalExpression "pkgs.llm-agents.pi";
        description = "The Pi package the dotfiles wrap and install.";
      };

      settings = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Keys merged into Pi's `~/.pi/agent/settings.json` on activation.";
        example = lib.literalExpression ''{theme = "gruber-darker";}'';
      };

      finalArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        internal = true;
        readOnly = true;
      };

      finalPackage = lib.mkOption {
        type = lib.types.package;
        internal = true;
        readOnly = true;
      };
    };

    config = lib.mkMerge [
      {
        programs.agents.pi = {
          inherit finalArgs;
          finalPackage = wrapped;
        };
      }

      (lib.mkIf (cfg.enable && piCfg.enable) {
        home.packages = [piCfg.finalPackage];

        home.activation.piSettings = lib.mkIf (piCfg.settings != {}) (
          lib.hm.dag.entryAfter ["writeBoundary"] ''
            run ${lib.getExe mergeSettings} \
              ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/settings.json"} \
              ${declaredSettings}
          ''
        );
      })
    ];
  }
