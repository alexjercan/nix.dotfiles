{
  config,
  pkgs,
  ...
}: {
  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;

    # Both are Turing+ only and experimental; upstream recommends false.
    # finegrained powers the GPU down when idle; open is the NVIDIA open
    # kernel module, not the third-party nouveau driver.
    powerManagement.finegrained = false;
    open = false;

    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %F' --remember --remember-session";
      user = "greeter";
    };
  };

  environment.etc."greetd/environments".text = ''
    startx
    uwsm start hyprland
  '';

  users.users.greeter = {
    isNormalUser = false;
    description = "greetd greeter user";
    extraGroups = ["video" "audio"];
    linger = true;
  };

  services.xserver = {
    enable = true;
    videoDrivers = ["nvidia"];
    desktopManager.xterm.enable = false;
    windowManager.i3.enable = true;
    displayManager.startx.enable = true;
    xkb = {
      layout = "us";
      variant = "";
      options = "caps:none";
    };
  };

  environment.etc."X11/xinit/xinitrc".text = ''
    #!/bin/sh
    if [ -f "$HOME/.xinitrc" ]; then
      . "$HOME/.xinitrc"
    else
      exec ${pkgs.i3}/bin/i3
    fi
  '';

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
}
