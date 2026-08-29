{...}: {
  networking.firewall.interfaces = {
    enp4s0 = {
      allowedTCPPorts = [139 445];
      allowedUDPPorts = [137 138];
    };
    tailscale0.allowedTCPPorts = [445];
  };

  services.samba = {
    enable = true;
    openFirewall = false;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "smbnix";
        "netbios name" = "smbnix";
        "security" = "user";
        "hosts allow" = "192.168.0.0/24 127.0.0.1 ::1 100.64.0.0/10 fd7a:115c:a1e0::/48";
        "hosts deny" = "ALL";
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
}
