# Everything Pi lives under this directory: the options, the theme files, and
# one self-contained module per extension.
#
# Hand-rolled rather than pi.nix's Home Manager module. This repo only ever
# needed settings, themes and extensions, and the package now comes from the
# llm-agents overlay, which tracks upstream releases closely. Resources use
# Pi's normal package and theme locations so the unwrapped CLI discovers them.
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
    enabledExtensions = lib.filterAttrs (_: ext: ext.enable) piCfg.extensions;

    # themes/module.nix declares one `themes.<name>` per file in themes/.
    enabledThemes = lib.filterAttrs (_: theme: theme.enable) piCfg.themes;

    packagePaths = map (name: "./packages/${name}") (lib.attrNames enabledExtensions);
    finalSettings =
      piCfg.settings
      // {
        packages = (piCfg.settings.packages or []) ++ packagePaths;
      };

    packageFiles = lib.mapAttrs' (name: ext:
      lib.nameValuePair ".pi/agent/packages/${name}" {source = ext.package;})
    enabledExtensions;

    themeFiles = lib.mapAttrs' (name: theme:
      lib.nameValuePair ".pi/agent/themes/${name}.json" {source = theme.source;})
    enabledThemes;

    json = pkgs.formats.json {};

    declaredSettings = pkgs.writeText "pi-settings.json" (builtins.toJSON finalSettings);

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
        # Replace packages managed below `./packages/`, but preserve packages
        # added interactively with `pi install`. Both branches go through jq so
        # a re-run compares equal and the activation stays idempotent.
        if [ -f "$target" ]; then
          jq -s '
            .[0] as $current
            | .[1] as $declared
            | ($current * $declared)
            | (($declared.packages // [])
                + (($current.packages // [])
                  | map(select(
                      (type != "string")
                      or (startswith("./packages/") | not)
                    )))) as $packages
            | .packages = reduce $packages[] as $package (
                [];
                if index($package) == null
                then . + [$package]
                else .
                end
              )
          ' "$target" "$declared" > "$tmp"
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
        description = "The Pi package the dotfiles install.";
      };

      settings = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Keys merged into Pi's `~/.pi/agent/settings.json` on activation.";
        example = lib.literalExpression ''{theme = "gruber-darker";}'';
      };

      # models.json is the custom-provider catalogue (pi/docs/models.md); the
      # binary reads no other name for it. Unlike settings.json, pi only reads
      # this file, so a plain store symlink replaces the activation merge.
      models = lib.mkOption {
        type = json.type;
        default = {};
        description = "Contents of Pi's `~/.pi/agent/models.json` custom-provider catalogue.";
        example = lib.literalExpression ''{providers.gemma.baseUrl = "http://localhost:10302/v1";}'';
      };
    };

    config = lib.mkIf (cfg.enable && piCfg.enable) {
      home.packages = [piCfg.package];

      home.file =
        packageFiles
        // themeFiles
        // lib.optionalAttrs (piCfg.models != {}) {
          ".pi/agent/models.json" = {
            source = json.generate "pi-models.json" piCfg.models;
          };
        };

      home.activation.piSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
        run ${lib.getExe mergeSettings} \
          ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent/settings.json"} \
          ${declaredSettings}
      '';
    };
  }
