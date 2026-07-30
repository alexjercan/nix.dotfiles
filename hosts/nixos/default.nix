# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: let
  # The variables held by secrets/scufris.yaml, in the order they are rendered
  # into the app's env file. This list is the ONLY place a scufris secret name
  # is written: it drives both the per-key sops secrets and the template below,
  # so a name cannot be spelled one way in one place and another way in the
  # other. Note that the NixOS EVALUATION accepts any name here - sops-nix's
  # `validateSopsFiles` only hashes the file, it never inspects its keys - so a
  # typo is caught by flake/checks.nix, which asserts this list and the
  # encrypted file hold exactly the same set, and failing that by
  # sops-install-secrets at activation.
  scufrisEnvVars = [
    "SCUFRIS_TELEGRAM_BOT_TOKEN"
    "SCUFRIS_AUTH_PASSWORD_HASH"
    "SCUFRIS_TELEGRAM_ALLOWED_CHAT_IDS"
    "SCUFRIS_HOSTD_SECRET"
  ];
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    inputs.scufris.nixosModules.scufris-hostd
    inputs.sops-nix.nixosModules.sops
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName is set by the flake from the host directory name
  # (see flake/nixos-configurations.nix), so it is not defined here.
  # networking.hostName = "nixos"; # Define your hostname.
  networking.nameservers = ["1.1.1.1" "9.9.9.9"];
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  hardware.graphics.enable = true;

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # NVIDIA container runtime
  hardware.nvidia-container-toolkit.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Bucharest";

  # Select internationalisation properties.
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

  # Create wrapper scripts for sessions
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

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    xkb.options = "caps:none";
    displayManager.sessionCommands = ''
      # This will be executed when starting X sessions
    '';
  };
  services.xserver.videoDrivers = ["nvidia"];
  services.xserver.desktopManager.xterm.enable = false;
  services.xserver.windowManager.i3.enable = true;

  # Create default xinitrc for users
  environment.etc."X11/xinit/xinitrc".text = ''
    #!/bin/sh
    # Default xinitrc for NixOS
    if [ -f "$HOME/.xinitrc" ]; then
      . "$HOME/.xinitrc"
    else
      # Start i3 by default
      exec ${pkgs.i3}/bin/i3
    fi
  '';

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  programs.hyprland.enable = true; # enable Hyprland
  programs.hyprland.withUWSM = true;

  # Optional, hint Electron apps to use Wayland:
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.alex = {
    isNormalUser = true;
    description = "alex";
    # `scufris` is what lets the systemd USER service reach the root helper's
    # socket: scufris-hostd creates /run/scufris-hostd as root:scufris 0750, so
    # without membership here the app cannot even traverse to the socket.
    extraGroups = ["networkmanager" "libvirtd" "wheel" "docker" "sambashare" "dialout" "video" "audio" "scufris"];
    shell = pkgs.fish;
  };

  # A DEDICATED group for the scufris socket, not a shared one. `users` is the
  # default primary group of every normal account, so using it would hand the
  # root helper's socket to every human user on the box.
  users.groups.scufris = {};

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

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
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

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

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

  # Allow users to start X without being root
  services.xserver.displayManager.startx.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      AllowUsers = ["alex"];
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedUDPPorts = [];
  # 8000: scufris web dashboard, exposed to the LAN (host bound to 0.0.0.0).
  # networking.firewall.allowedTCPPorts = [];
  # networking.firewall.allowedUDPPortRanges = [];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Extra firewall rules for llama-cpp and my other services that need to be
  # exposed to the LAN but not the Internet.
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp -s 172.16.0.0/12 --dport 11433 -j nixos-fw-accept
    iptables -A nixos-fw -p tcp -s 192.168.0.0/24 --dport 11433 -j nixos-fw-accept
    iptables -A nixos-fw -p tcp -s 192.168.0.0/24 --dport 8000 -j nixos-fw-accept
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -p tcp -s 172.16.0.0/12 --dport 11433 -j nixos-fw-accept 2>/dev/null || true
    iptables -D nixos-fw -p tcp -s 192.168.0.0/24 --dport 11433 -j nixos-fw-accept 2>/dev/null || true
    iptables -D nixos-fw -p tcp -s 192.168.0.0/24 --dport 8000 -j nixos-fw-accept 2>/dev/null || true
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

  # Storage optimization
  nix.optimise.automatic = true;
  nix.optimise.dates = ["03:45"];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # scufris secrets. ONE encrypted file, decrypted once, here at the SYSTEM
  # level, feeding two units that live in two different evaluations:
  #
  #   * scufris-hostd (below), a root unit, needs the shared socket credential
  #     as a RAW file - it reads --secret-file whole and strips it.
  #   * the scufris app, a home-manager USER service, needs a complete
  #     `KEY=value` env file for its EnvironmentFile.
  #
  # Decryption is at the system level rather than in home-manager because the
  # root unit starts at boot, long before any user session exists: a secret
  # rendered into $XDG_RUNTIME_DIR at home-manager activation is simply not
  # there yet, and is gone again whenever alex logs out. See
  # tasks/20260730-190929/DECISION.md.
  #
  # The key is the machine's own: sops.age.sshKeyPaths defaults to
  # /etc/ssh/ssh_host_ed25519_key, whose age form is a recipient in .sops.yaml
  # alongside my per-user key. Nothing here reads anything out of /home.
  sops.secrets = lib.genAttrs scufrisEnvVars (name: {
    sopsFile = "${inputs.self}/secrets/scufris.yaml";
    # Each secret is named after the variable it holds, so `key` (which defaults
    # to the attribute name) selects the right entry with nothing to keep in
    # sync. Per-key extraction is why this file is YAML and not the dotenv it
    # used to be: sops-nix ignores `key` for dotenv/ini/binary and always
    # decrypts whole-file (LESSONS.md sops-dotenv-decrypts-whole-file).
    mode = "0400";
    # Rotating the credential must restart the helper that holds it; the app
    # side is a user service and is restarted by `home-manager switch`.
    restartUnits = lib.optional (name == "SCUFRIS_HOSTD_SECRET") "scufris-hostd.service";
  });

  # The app's env file, assembled from the same secrets. Rendered at activation
  # into /run/secrets/rendered/, never the nix store: `content` holds opaque
  # placeholder tokens at eval time and sops-nix substitutes the real values in
  # place. home/alex/default.nix reads this path.
  sops.templates."scufris.env" = {
    owner = "alex";
    mode = "0400";
    content = lib.concatMapStringsSep "\n" (name: "${name}=${config.sops.placeholder.${name}}") scufrisEnvVars;
  };

  services.scufris-hostd = {
    enable = true;
    group = "scufris";                              # a DEDICATED group, not `users`
    # The RAW single-value secret, NOT the env file above: scufris-hostd reads
    # this file whole and strips it, so handing it a `KEY=value` blob would make
    # every frame fail authentication.
    secretFile = config.sops.secrets."SCUFRIS_HOSTD_SECRET".path;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
