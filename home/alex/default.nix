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

      # Agent: the orchestrator chat. Codex app-server backend by default,
      # authenticated with a ChatGPT subscription (`scufris login` / `codex login`).
      agent_enabled = true;
      agent_backend = "app_server";
      agent_model = "gpt-5.5";
      agent_auth_mode = "chatgpt";
    };

    # State is shared with local dev (default ~/.local/state/scufris); dev runs
    # on a different port (SCUFRIS_PORT=7000 in the repo .env) so only the port
    # differs, not the state.
    # Secrets (e.g. SCUFRIS_OPENAI_API_KEY for api_key auth) load from here at
    # service start, kept out of the nix store.
    environmentFile = "${config.home.homeDirectory}/.config/scufris/env";

    # Agent backends are operator-installed binaries the server shells out to
    # (never Python deps); git is needed for codex/claude in a project cwd.
    path = [pkgs.codex pkgs.claude-code pkgs.git];
  };

  home.pointerCursor = {
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
