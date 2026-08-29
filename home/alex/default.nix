{
  pkgs,
  inputs,
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
    "${modulesPath}/scufris"
    "${modulesPath}/newsboat"
    "${modulesPath}/gtk-theme"
    "${modulesPath}/gc"
    inputs.scufris.homeModules.default
  ];
}
