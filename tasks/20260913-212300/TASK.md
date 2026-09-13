# Remove scufris from home configuration

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: config

Removed the Scufris Home Manager module, flake input, checks, and obsolete
sops-nix secret infrastructure. Removed every `.scufris.toml` file under
`/home/alex`.

Verification:

- `nix build .#homeConfigurations.alex.activationPackage --no-link`
- Repository scan has no current Scufris or sops references outside task history.
- Filesystem scan has no `.scufris.toml` files under `/home/alex`.
