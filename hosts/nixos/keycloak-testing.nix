# Optional testing stack: PostgreSQL + Keycloak, exposed to the LAN.
#
# This is scratch infrastructure used to test things, not something meant to run
# all the time. It is off by default. Flip `local.keycloak.enable = true;` in the
# host config to turn the whole stack (database, identity server and the LAN
# firewall rules) on, and back to false to stop running it.
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.local.keycloak;
in {
  options.local.keycloak = {
    enable = lib.mkEnableOption "the PostgreSQL + Keycloak testing stack (LAN only)";
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_17;

      # Listen on all interfaces so the LAN can reach it. Access is still
      # gated by the authentication rules and the firewall below.
      enableTCPIP = true;
      settings.listen_addresses = lib.mkForce "*";

      # Allow password-authenticated connections from the local LAN subnet.
      authentication = lib.mkOverride 10 ''
        # type  database  user  address           auth-method
        local   all       all                     peer
        host    all       all   127.0.0.1/32      scram-sha-256
        host    all       all   ::1/128          scram-sha-256
        host    all       all   192.168.0.0/24   scram-sha-256
      '';
    };

    # Keycloak identity server. Uses the local PostgreSQL above: with
    # createLocally the module provisions the `keycloak` role and database and
    # connects over localhost:5432, which the pg_hba rules already allow with
    # scram-sha-256. The DB password is read from a machine-local file that is
    # deliberately kept out of git (see the note below).
    services.keycloak = {
      enable = true;

      database = {
        type = "postgresql";
        createLocally = true;
        # Create this file on the host, it is not tracked in git:
        #   sudo install -d -m 0755 /etc/keycloak
        #   umask 077; openssl rand -hex 24 | sudo tee /etc/keycloak/db-password
        #   sudo chmod 0600 /etc/keycloak/db-password
        passwordFile = "/etc/keycloak/db-password";
      };

      # Temporary bootstrap admin. Change this password immediately in the admin
      # console after the first login, it is stored world-readable in the Nix store.
      initialAdminPassword = "changeme";

      settings = {
        # Serve plain HTTP on the LAN, no TLS. Bind all interfaces (default "::"
        # covers IPv4 too) and let Keycloak infer its public URL from the request
        # host so it works when reached by the machine's LAN IP.
        http-enabled = true;
        http-port = 7001;
        hostname-strict = false;
      };
    };

    # Expose PostgreSQL and Keycloak to the LAN only. These rules restrict the
    # ports to the local subnet instead of using the global allowedTCPPorts.
    networking.firewall.extraCommands = ''
      iptables -A nixos-fw -p tcp --source 192.168.0.0/24 --dport 5432 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp --source 192.168.0.0/24 --dport 7001 -j nixos-fw-accept
    '';
  };
}
