{...}: {
  networking = {
    nameservers = ["1.1.1.1" "9.9.9.9"];
    networkmanager.enable = true;

    firewall = {
      interfaces."tailscale0".allowedTCPPorts = [22 10300];

      # Expose local inference services to the LAN only.
      extraCommands = ''
        iptables -A nixos-fw -p tcp -s 192.168.0.0/24 --dport 8000 -j nixos-fw-accept
        iptables -A nixos-fw -p tcp -s 192.168.0.0/24 --dport 10300 -j nixos-fw-accept
      '';
      extraStopCommands = ''
        iptables -D nixos-fw -p tcp -s 192.168.0.0/24 --dport 8000 -j nixos-fw-accept 2>/dev/null || true
        iptables -D nixos-fw -p tcp -s 192.168.0.0/24 --dport 10300 -j nixos-fw-accept 2>/dev/null || true
      '';
    };
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "none";
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      AllowUsers = ["alex"];
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
