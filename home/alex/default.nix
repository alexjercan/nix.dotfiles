{
  pkgs,
  inputs,
  config,
  ...
}: let
  # Subpath of the flake source, not a `../modules` path literal: every use
  # below interpolates it into a string, and coercing a path literal that way
  # copies the directory to a floating `<hash>-modules` store root that GC
  # reaps out from under the eval cache. `nix flake check` then fails with
  # "path '<hash>-modules' is not valid" until someone re-adds it by hand. Same
  # reason as `homeDir` in flake/home-configurations.nix, and LESSONS.md
  # `flake-path-literal-string-coercion`.
  modulesPath = "${inputs.self}/home/modules";
in {
  home.username = "alex";
  home.homeDirectory = "/home/alex";

  # NOTE: allowUnfree is intentionally NOT set here. This home config is built
  # with an externally-imported pkgs (flake/home-configurations.nix does
  # `import nixpkgs { config.allowUnfree = true; ... }`), so an in-module
  # `nixpkgs.config` is ignored. The effective setting lives on that import;
  # setting it here would be inert. See LESSONS.md
  # `hm-external-pkgs-ignores-nixpkgs-config`.
  # nixpkgs.config.allowUnfree = true;

  # WARNING: do not change. Pins the Home Manager release this config is
  # compatible with; bumping it silently changes stateful defaults. Read the
  # Home Manager release notes first.
  home.stateVersion = "24.05";

  home.file = {
    ".xinitrc" = {
      text = ''
        #!/bin/sh
        exec ${pkgs.i3}/bin/i3
      '';
      executable = true;
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  xsession.enable = true;

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

      # Dashboard authentication. A LAN-reachable bind (host above, plus the
      # 192.168.0.0/24 -> 8000 firewall rule in hosts/nixos) means anything on
      # the network could otherwise create agents and drive the orchestrator.
      # Explicit rather than relying on the default ("auto" would already
      # require it for a non-loopback bind, and SCUFRIS_HOSTD_SECRET being set
      # forces it too) - the two implicit paths both happen to be right today,
      # which is exactly why the intent is worth stating outright.
      #
      # FAIL-CLOSED: the service REFUSES TO START without
      # SCUFRIS_AUTH_PASSWORD_HASH, which lives in secrets/scufris.yaml:
      #
      #     scufris hash-password     # prints the scrypt hash, never the password
      #     sops secrets/scufris.yaml # paste it as the value
      auth_mode = "required";

      # The orchestrator's backend: codex, claude, opencode, or mock.
      agent_backend = "codex";

      # the-den journal: the orchestrator's journal_* MCP tools shell out to
      # `today` (on `path` below) against this den. Set explicitly because the
      # systemd user service does NOT inherit the DEN_PATH session var (that is
      # only in the interactive shell env); mirrors home/modules/scripts.
      den_path = "/home/alex/personal/the-den";

      # This host's NixOS flake, for the R3 host actions. Read only - nothing
      # here writes to it; changes go through scufris-hostd's proposal flow.
      host_config_repo = "/home/alex/personal/nix.dotfiles";

      # Auto-wake: when a sub-agent finishes awaiting a decision (a WAITING
      # outcome) or errors, grant the orchestrator a turn with the question
      # injected, so a stalled loop self-heals without me driving it from the
      # chat. Off by default upstream because a wake runs the orchestrator
      # unattended in its `auto` permission mode; enabled here deliberately so
      # the Telegram bot is a hands-off control surface.
      auto_wake = 1;

      # NOTE: the Telegram chat allowlist is NOT here. It lives in
      # secrets/scufris.yaml as SCUFRIS_TELEGRAM_ALLOWED_CHAT_IDS, because
      # `settings` lands in the world-readable nix store and that allowlist IS
      # the bot's auth - an empty list ignores everyone, so my chat id must be
      # set for the bot to respond at all.
    };

    # Secrets go HERE, never in `settings` (which lands in the nix store).
    #
    # A LITERAL path, not a typed reference: this file is rendered by
    # `sops.templates."scufris.env"` in hosts/nixos/default.nix, and that is a
    # NixOS evaluation while this is a standalone home-manager one - the two
    # cannot share a `config`. flake/checks.nix asserts the two sides still
    # name the same path, so a change on either side fails `nix flake check`
    # rather than silently starting the service with no secrets.
    #
    # Decryption happens at the SYSTEM level (at boot, keyed to the machine's
    # SSH host key), not at home-manager activation, so the root scufris-hostd
    # unit and this user service read from one source. See
    # tasks/20260730-190929/DECISION.md.
    environmentFile = "/run/secrets/rendered/scufris.env";

    # Agent backends are operator-installed binaries the server shells out to
    # (never Python deps); git is needed for codex/claude in a project cwd.
    # `today` (from inputs.today.overlays.default) backs the journal_* MCP tools,
    # and `macros` (inputs.macros-nvim.overlays.default) backs the macros_* tools.
    # `nvidia_x11.bin` provides nvidia-smi, which backs the GPU stats page: the
    # HM user service overrides PATH, so without it nvidia-smi is unreachable and
    # the dashboard shows `gpus: []`. nvidia-smi/NVML must match the LOADED
    # kernel module or it errors "Driver/library version mismatch" and the page
    # silently falls back to `gpus: []`. This matches today because the host
    # (hosts/nixos) runs the DEFAULT kernel with `nvidiaPackages.stable`, so
    # `linuxPackages.nvidia_x11` == the host's `hardware.nvidia.package` (same
    # nixpkgs input, same driver). If the host ever pins a non-default kernel or
    # a beta/legacy/production nvidia package, switch this to reference that
    # same driver instead.
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
