{
  pkgs,
  inputs,
  config,
  ...
}: let
  modulesPath = ../modules;
in {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "alex";
  home.homeDirectory = "/home/alex";

  # NOTE: allowUnfree is intentionally NOT set here. This home config is built
  # with an externally-imported pkgs (flake/home-configurations.nix does
  # `import nixpkgs { config.allowUnfree = true; ... }`), so an in-module
  # `nixpkgs.config` is ignored. The effective setting lives on that import;
  # setting it here would be inert. See LESSONS.md
  # `hm-external-pkgs-ignores-nixpkgs-config`.
  # nixpkgs.config.allowUnfree = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # Packages live in topical sub-modules under home/modules/packages (cli, dev,
  # media, apps, games, desktop, fonts), imported below.

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';

    ".xinitrc" = {
      text = ''
        #!/bin/sh
        # Start i3 window manager
        exec ${pkgs.i3}/bin/i3
      '';
      executable = true;
    };
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/alex/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  xsession.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    lfs.enable = true;
    signing.format = null;
    settings.user.name = "Alex Jercan";
    settings.user.email = "jercan_alex27@yahoo.com";
  };

  programs.newsboat = {
    enable = true;
    urls = [
      {url = "https://xkcd.com/rss.xml";}
      {url = "https://alexjercan.github.io/rss.xml";}
    ];
  };

  # sops-nix PoC (task 20260722-214112, see tasks/20260722-113105/RECOMMENDATION.md).
  # Encrypted-in-repo secrets via a DEDICATED passwordless age key per machine
  # (~/.config/sops/age/keys.txt, generated with age-keygen, kept out of the repo
  # and the store). The secret file is a sops DOTENV (secrets/scufris.env),
  # decrypted at activation into $XDG_RUNTIME_DIR by the sops-nix user service.
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # Reference the secret as a subpath of the flake source (inputs.self), NOT a
    # `../../secrets` path literal - see LESSONS.md flake-path-literal-string-coercion.
    #
    # `format = "dotenv"` decrypts the WHOLE file as this secret's value, so the
    # attr name is just the runtime output file name. It is not a per-key
    # selector. The decrypted file at `.path` is already a complete `KEY=value`
    # env file that scufris can load directly via environmentFile.
    secrets."scufris-env" = {
      sopsFile = "${inputs.self}/secrets/scufris.env";
      format = "dotenv";
    };
  };

  # The scufris user service must start after sops-nix has decrypted the secret,
  # or environmentFile points at a not-yet-existing path.
  systemd.user.services.scufris.Unit.After = ["sops-nix.service"];

  # scufris is now the local web-dashboard server (replaces the old bot). Config
  # is a flat attrset mapping to SCUFRIS_ env vars (scufris/config.py). The built
  # dashboard is served from the packaged web derivation via SCUFRIS_WEB_DIST
  # (wired automatically by the module).
  programs.scufris = {
    enable = true;

    settings = {
      # Bind all interfaces so the dashboard is reachable from the LAN, not
      # just loopback.
      host = "0.0.0.0";
      port = 8000;
      log_level = "INFO";

      # Dashboard authentication. A LAN-reachable bind (host above, plus the
      # 192.168.0.0/24 -> 8000 firewall rule in hosts/nixos) means anything on
      # the network could otherwise create agents and drive the orchestrator.
      # "required" is explicit here; scufris's own default ("auto") would
      # already require it for a non-loopback bind.
      #
      # This is FAIL-CLOSED: the service REFUSES TO START unless
      # SCUFRIS_AUTH_PASSWORD_HASH is set. That variable is a secret, so it does
      # not belong here - add it to the sops dotenv below:
      #
      #     nix run nixpkgs#scufris -- hash-password   # or `scufris hash-password`
      #     sops secrets/scufris.env                   # paste the printed line
      #
      # The hash (scrypt), never the password, is what is stored. Only takes
      # effect once the scufris flake input is bumped past v0.1.0, which is the
      # release that introduces the option - until then this is inert (unknown
      # SCUFRIS_ vars are ignored).
      auth_mode = "required";

      # Agent: the orchestrator chat. Codex app-server backend by default,
      # authenticated with a ChatGPT subscription (`scufris login` / `codex login`).
      agent_enabled = true;
      agent_backend = "app_server";
      agent_model = "gpt-5.5";
      agent_auth_mode = "chatgpt";

      # the-den journal: the orchestrator's journal_* MCP tools shell out to
      # `today` (on `path` below) against this den. Set explicitly because the
      # systemd user service does NOT inherit the DEN_PATH session var (that is
      # only in the interactive shell env); mirrors home/modules/scripts DEN_PATH.
      den_path = "/home/alex/personal/the-den";

      # Telegram frontend: with SCUFRIS_TELEGRAM_BOT_TOKEN set (from the sops
      # secret above), the app runs an in-process long-poll bot that drives the
      # same orchestrator turn path as the web landing chat. This allowlist IS
      # the auth - the bot silently ignores updates from any other chat id, and
      # an empty list ignores EVERYONE - so my own chat id must be listed for the
      # bot to respond at all. (SCUFRIS_TELEGRAM_ALLOWED_CHAT_IDS)
      telegram_allowed_chat_ids = 8231376426;

      # Auto-wake: when a sub-agent finishes awaiting a decision (a WAITING
      # outcome) or errors, grant the orchestrator a turn with the question
      # injected, so a stalled loop self-heals without me driving it from the
      # chat. Off by default upstream because a wake runs the orchestrator
      # unattended in its `auto` permission mode; enabled here deliberately so
      # the Telegram bot is a hands-off control surface. (SCUFRIS_AUTO_WAKE)
      auto_wake = 1;
    };

    # State is shared with local dev (default ~/.local/state/scufris); dev runs
    # on a different port (SCUFRIS_PORT=7000 in the repo .env) so only the port
    # differs, not the state.
    # The dotenv secret above is decrypted at activation into $XDG_RUNTIME_DIR
    # (never in the nix store) as a complete `KEY=value` env file, so point
    # environmentFile straight at it. Add more secret env vars by editing
    # `secrets/scufris.env` with sops; this path always resolves to the full
    # decrypted env file.
    environmentFile = config.sops.secrets."scufris-env".path;

    # Agent backends are operator-installed binaries the server shells out to
    # (never Python deps); git is needed for codex/claude in a project cwd.
    # `today` (from inputs.today.overlays.default) backs the journal_* MCP tools,
    # and `macros` (inputs.macros-nvim.overlays.default) backs the macros_* tools.
    # `nvidia_x11.bin` provides nvidia-smi, which backs the GPU stats page: the
    # HM user service overrides PATH, so without it nvidia-smi is unreachable and
    # the dashboard shows `gpus: []` (works locally only because the interactive
    # shell PATH has /run/current-system/sw/bin). nvidia-smi/NVML must match the
    # LOADED kernel module or it errors "Driver/library version mismatch" and the
    # page silently falls back to `gpus: []`. This matches today because the host
    # (hosts/nixos) runs the DEFAULT kernel with `nvidiaPackages.stable`, so
    # `linuxPackages.nvidia_x11` == the host's `hardware.nvidia.package` (same
    # nixpkgs input, same driver). If the host ever pins a non-default kernel or a
    # beta/legacy/production nvidia package, switch this to reference that same
    # driver instead.
    path = [pkgs.codex pkgs.claude-code pkgs.git pkgs.today pkgs.macros pkgs.linuxPackages.nvidia_x11.bin];
  };

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
  };

  gtk = {
    enable = true;

    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };

    theme = {
      name = "Graphite-Dark";
      package = pkgs.graphite-gtk-theme;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.theme = null;

    font = {
      name = "Iosevka Bold";
      size = 11;
    };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  imports = [
    "${modulesPath}/neovim"
    "${modulesPath}/tmux"
    "${modulesPath}/rofi"
    "${modulesPath}/kitty"
    "${modulesPath}/i3"
    "${modulesPath}/hyprland"
    "${modulesPath}/dunst"
    "${modulesPath}/packages"
    "${modulesPath}/scripts"
    "${modulesPath}/agents"
    inputs.scufris.homeManagerModules.default
  ];
}
