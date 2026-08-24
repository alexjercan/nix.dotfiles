# Decisions

- Pin the public `v0.1.0` GitHub tag by fixed-output source hash.
- Package only the upstream Pi package contents, not repository development files.
- Follow the existing `pi-extensions/<name>/{default,module}.nix` discovery pattern.
- Expose `enable` and overridable `package` options, then enable Quick Review in the user defaults.
