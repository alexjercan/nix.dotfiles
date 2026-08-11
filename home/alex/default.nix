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

  programs.agents = {
    enable = true;
    skills.today = inputs.today.skills.today;
  };

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
    inputs.agents.homeModules.personal
  ];
}
