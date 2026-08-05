{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.sops-nix.nixosModules.sops
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName is set by the flake from the host directory name
  # (see flake/nixos-configurations.nix), so it is not defined here.
  # networking.hostName = "nixos"; # Define your hostname.
  networking.nameservers = ["1.1.1.1" "9.9.9.9"];
  networking.networkmanager.enable = true;

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

  hardware.nvidia-container-toolkit.enable = true;

  time.timeZone = "Europe/Bucharest";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.greetd = {
    enable = true;
    useTextGreeter = true;

    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %F' --remember --remember-session";
        user = "greeter";
      };
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
    xkb.options = "caps:none";
  };
  services.xserver.videoDrivers = ["nvidia"];
  services.xserver.desktopManager.xterm.enable = false;
  services.xserver.windowManager.i3.enable = true;

  environment.etc."X11/xinit/xinitrc".text = ''
    #!/bin/sh
    if [ -f "$HOME/.xinitrc" ]; then
      . "$HOME/.xinitrc"
    else
      exec ${pkgs.i3}/bin/i3
    fi
  '';

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  programs.hyprland.enable = true; # enable Hyprland
  programs.hyprland.withUWSM = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.alex = {
    isNormalUser = true;
    description = "alex";
    extraGroups = ["networkmanager" "libvirtd" "wheel" "docker" "sambashare" "dialout" "video" "audio"];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
  programs.nix-ld.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = with pkgs; [
    alejandra
    file
    gcc
    git
    gnumake
    htop
    kitty # required for the default Hyprland config
    lsof
    man-pages
    man-pages-posix
    nvtopPackages.nvidia
    pv
    python3
    sops
    tuigreet
    vim
    wget
    xinit
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.sauce-code-pro
  ];

  virtualisation.docker.enable = true;
  virtualisation.docker.autoPrune = {
    enable = true;
    dates = "weekly";
    flags = ["--all"]; # also removes unused images; omit for images-in-use-only
  };

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  services.xserver.displayManager.startx.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      AllowUsers = ["alex"];
    };
  };

  # Extra firewall rules for llama-cpp and my other services that need to be
  # exposed to the LAN but not the Internet.
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp -s 172.16.0.0/12 --dport 11433 -j nixos-fw-accept
    iptables -A nixos-fw -p tcp -s 192.168.0.0/24 --dport 11433 -j nixos-fw-accept
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -p tcp -s 172.16.0.0/12 --dport 11433 -j nixos-fw-accept 2>/dev/null || true
    iptables -D nixos-fw -p tcp -s 192.168.0.0/24 --dport 11433 -j nixos-fw-accept 2>/dev/null || true
  '';

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "smbnix";
        "security" = "user";
        "hosts allow" = "192.168.0. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      "public" = {
        "path" = "/home/alex/Shared/public";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "alex";

        "fruit:aapl" = "yes";
        "fruit:time machine" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
      };
    };
  };

  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp.override {cudaSupport = true;};
    openFirewall = false;
    settings = {
      host = "0.0.0.0";
      port = 11433;
      ctx-size = 128000;
      models-preset =
        pkgs.writeText "llama-cpp-models-preset.ini"
        (lib.generators.toINI {} {
          "Qwen3.6-35B-A3B" = {
            hf-repo = "ggml-org/Qwen3.6-35B-A3B-GGUF";
            hf-file = "Qwen3.6-35B-A3B-Q8_0.gguf";
            alias = "ggml-org/Qwen3.6-35B-A3B";
            fit = "on";
            seed = "3407";
            temp = "0.2";
            top-p = "0.9";
            min-p = "0.05";
            top-k = "20";
            repeat-penalty = "1.05";
            repeat-last-n = "256";
            dry-multiplier = "0.5";
            dry-base = "1.75";
            dry-allowed-length = "8";
            dry-penalty-last-n = "4096";
            jinja = "on";
          };
          "gemma-4-26B-A4B-it" = {
            hf-repo = "ggml-org/gemma-4-26B-A4B-it-GGUF";
            hf-file = "gemma-4-26B-A4B-it-Q8_0.gguf";
            alias = "ggml-org/gemma-4-26B-A4B-it-GGUF";
            fit = "on";
            seed = "3407";
            temp = "0.2";
            top-p = "0.9";
            min-p = "0.05";
            top-k = "20";
            repeat-penalty = "1.05";
            repeat-last-n = "256";
            dry-multiplier = "0.5";
            dry-base = "1.75";
            dry-allowed-length = "8";
            dry-penalty-last-n = "4096";
            jinja = "on";
          };
        });
    };
  };

  systemd.services.cache-cleanup = {
    description = "Prune llama-cpp model cache";
    serviceConfig.Type = "oneshot";
    path = [pkgs.python3Packages.huggingface-hub];
    script = ''
      hf cache prune --cache-dir /var/cache/private/llama-cpp
    '';
  };
  systemd.timers.cache-cleanup = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
    };
  };

  services.logmein-hamachi.enable = true;
  documentation.man.cache.enable = false;

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1month
  '';

  nix.optimise.automatic = true;
  nix.optimise.dates = ["03:45"];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # WARNING: do not change. Pins stateful defaults (file locations, database
  # versions) to the release this system was first installed with.
  system.stateVersion = "24.05";
}
