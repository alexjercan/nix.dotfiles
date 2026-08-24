# Verification

- Prefetched `v0.1.1` as `sha256-eN585HEqYQr5mh6I7Uh8kjVFVxJNtkR4HV7ZT7lQjmI=`.
- `nix build .#checks.x86_64-linux.quick-review -L --no-link`: passed.
- `nix build .#homeConfigurations.alex.activationPackage -L --no-link`: passed.
- Alejandra checks for both changed Nix files: passed.
- `git diff --check`: passed.
