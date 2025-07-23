{
  pkgs,
  dzgui,
  ...
}: {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "alex";
  home.homeDirectory = "/home/alex";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    hello

    audacity
    blender
    btop
    chromium
    dconf
    discord
    dunst
    fd
    feh
    ffmpeg
    firefox
    fzf
    gimp
    i3lock
    i3status-rust
    iosevka
    jq
    kdePackages.kdenlive
    kitty
    libnotify
    libreoffice-qt
    lxappearance
    mpv
    mupdf
    neofetch
    networkmanager-openvpn
    networkmanagerapplet
    nitrogen
    obs-studio
    openssl
    openvpn
    pcmanfm
    poetry
    prismlauncher
    pw-volume
    pwvucontrol
    rar
    ripgrep
    scrot
    unzip
    virt-manager
    wesnoth
    xclip
    zip
    dust
    dua

    brave
    dzgui.packages.x86_64-linux.default

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  fonts.fontconfig.enable = true;

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
    userName = "Alex Jercan";
    userEmail = "jercan_alex27@yahoo.com";
  };

  services.scufris = {
      enable = false;
  };

  gtk = {
    enable = true;
    # iconTheme = {
    #   name = "Tela circle dark";
    #   package = pkgs.tela-circle-icon-theme;
    # };

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
  };

  imports = [
    ./neovim
    ./tmux
    ./rofi
    ./kitty
    ./i3
    ./dunst
    ./scripts
  ];
}
