# Keycloak on the nixos host

A PostgreSQL + Keycloak identity server for the nixos host, reachable from the
local LAN over plain HTTP. It is scratch/testing infrastructure, so it lives in
its own module (`hosts/nixos/keycloak-testing.nix`) behind a toggle and is off by
default.

## Turning it on / off

The whole stack (database, identity server, LAN firewall rules) is gated by a
single option. In `hosts/nixos/default.nix`:

```nix
local.keycloak.enable = true;   # false to stop running it
```

Then `sudo nixos-rebuild switch --flake .#nixos`. When disabled nothing from the
stack is built or run.

## What was added

- `services.keycloak` with:
  - `database.type = "postgresql"`, `database.createLocally = true` so the module
    provisions the `keycloak` Postgres role and database itself and connects over
    `localhost:5432`.
  - `database.passwordFile = "/etc/keycloak/db-password"`, a machine-local secret
    kept out of git.
  - `initialAdminPassword = "changeme"`, a temporary bootstrap admin to change on
    first login.
  - `settings.http-enabled = true`, `http-port = 7001`, `hostname-strict = false`.
- A LAN-scoped firewall rule for TCP 7001 in `networking.firewall.extraCommands`,
  alongside the existing Postgres 5432 rule. Port 8080 stays open globally for
  other uses; Keycloak uses 7001 to avoid clashing with it.

## Why these decisions

- Reused the already-present PostgreSQL 17 rather than standing up a separate DB.
  The NixOS module's `createLocally` init unit runs as the `postgres` user, creates
  the `keycloak` role with the password from `passwordFile`, and Keycloak connects
  back over loopback. The existing `pg_hba` rules already allow `127.0.0.1/32` and
  `::1/128` with `scram-sha-256`, so no auth changes were needed.
- Plain HTTP, no TLS: this is an internal LAN service. `hostname-strict = false`
  lets Keycloak infer its public URL from the request host, so it works when
  reached by the machine's LAN IP without pinning a hostname.
- LAN-only exposure: mirrors the deliberate Postgres scoping. Opening 8080 only to
  `192.168.0.0/24` keeps Keycloak off other interfaces, including the Hamachi VPN.
  The DB password is never committed; it lives at `/etc/keycloak/db-password` with
  `0600` perms.

## Host setup (run once, needs root)

Set `local.keycloak.enable = true;` first, then:

```sh
sudo install -d -m 0755 /etc/keycloak
umask 077; openssl rand -hex 24 | sudo tee /etc/keycloak/db-password >/dev/null
sudo chmod 0600 /etc/keycloak/db-password
sudo nixos-rebuild switch --flake .#nixos
```

Then open `http://<host-lan-ip>:7001/` from another LAN machine, log in as `admin`
/ `changeme`, and change the admin password immediately.

## Notes / follow-ups

- The bootstrap admin password sits world-readable in the Nix store. Fine for a
  throwaway first login; rotate it in the console right away. A future improvement
  is to drop `initialAdminPassword` and bootstrap the admin out of band.
- If TLS is wanted later, put Keycloak behind a reverse proxy (set
  `settings.proxy-headers = "xforwarded"` and a real `hostname`) or configure
  `sslCertificate`/`sslCertificateKey` directly.
