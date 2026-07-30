# Decision: how one sops secret reaches both a user service and a root unit

- STATUS: ACCEPTED
- DATE: 2026-07-30
- TASK: 20260730-190929
- TAGS: decision, nix, security, sops, scufris

## Context

`scufris` runs as two units that must share one credential:

- the app, a home-manager systemd USER service, which receives secrets as a
  full `KEY=value` file through `programs.scufris.environmentFile`; and
- `scufris-hostd`, a NixOS SYSTEM unit running as root, whose `--secret-file`
  is read whole and `.strip()`ed as the secret itself
  (`scufris/hostd/main.py:59`).

The credential (`SCUFRIS_HOSTD_SECRET`) is what distinguishes scufris from any
other process running as alex when it connects to the root helper's socket, so
the two sides holding the SAME value is the whole security property. It must
therefore be written down once.

Today the repo has exactly one sops instance, at the home-manager level
(`flake/home-configurations.nix:39`), decrypting `secrets/scufris.env` as a
dotenv into `$XDG_RUNTIME_DIR` with a per-user age key.

## Decision

### D1: system-level sops is the sole decryptor

Import `inputs.sops-nix.nixosModules.sops` into `hosts/nixos` and
make the NixOS level the only place decryption happens. It emits two derived
outputs from one encrypted file:

- `sops.secrets."scufris-hostd-secret"` (`key = "SCUFRIS_HOSTD_SECRET"`) ->
  `/run/secrets/scufris-hostd-secret`, a raw one-line root-only file, for the
  helper's `secretFile`;
- `sops.templates."scufris.env"` -> `/run/secrets/rendered/scufris.env`, a
  complete env file owned by alex, for the app's `environmentFile`.

Home-manager drops its own `sops` block and refers to the rendered path as a
LITERAL STRING.

### D2: the system decrypts with the host SSH key

Leave `sops.age.sshKeyPaths` at its default, so the system
decrypts with `/etc/ssh/ssh_host_ed25519_key` (openssh is enabled and the key
exists). Convert its public half with `ssh-to-age`, add it to `.sops.yaml` as a
`&host_nixos` anchor beside `&alex_nixos`, and `sops updatekeys` the secret.

## Alternatives considered

### D1: system-level sops is the sole decryptor

- *Both levels decrypt the same file.* HM keeps its sops and renders the env
  file itself; NixOS adds only the raw hostd secret. Keeps `home/alex`
  self-contained and portable to non-NixOS (the model `secrets/README.md`
  describes). Rejected: two decryptors and two key setups for one value, and
  the app's env file would still only exist after home-manager activation while
  the root unit's exists at boot - two lifetimes for one credential.
- *Fold home-manager into the NixOS configuration* (`home-manager.nixosModules`).
  One eval, so `home/alex` could write
  `osConfig.sops.templates."scufris.env".path` with no hardcoded string.
  Rejected for now: it is the largest refactor of the three, it deletes the
  standalone `home-manager switch` workflow, and it buys only type-safety on a
  path that sops-nix's own module fixes by default.
- *Keep the HM secret and point the root unit at `/run/user/1000/...`.*
  Rejected outright: the root unit is `wantedBy = multi-user.target` and
  fail-closed, while that directory does not exist before login and disappears
  at logout (no lingering). It would fail at every boot.

### D2: the system decrypts with the host SSH key

Point `sops.age.keyFile` at
`/home/alex/.config/sops/age/keys.txt` - no re-keying, no `.sops.yaml` change.
Rejected: it has a root boot-time service read a key out of a user's home
directory, and it leaves the secret with a single recipient, so losing the alex
key locks the machine out of its own credential too.

## Consequences

### D1: system-level sops is the sole decryptor

- Accepted cost: the rendered path is duplicated as a string across the two
  evals. Mitigated by a comment on each side naming the other.
- Accepted cost: `home/alex` gains a NixOS-specific assumption. Acceptable
  because `scufris-hostd` is a NixOS module and this machine is the only
  consumer; a future non-NixOS host would re-add a local sops block for the env
  file only.
- Forced consequence: `secrets/scufris.env` becomes `secrets/scufris.yaml`.
  `format = "dotenv"` has NO per-key extraction - `sops-install-secrets`
  ignores `key` for `Binary|Dotenv|Ini` and always writes the whole file
  (`main.go:340-375`; ledger `sops-dotenv-decrypts-whole-file`) - so a dotenv
  source cannot produce D1's raw single-value file at all.
- Gain: the credential exists at boot, independent of any login session, for
  both units; and rotating it can `restartUnits` the helper.

### D2: the system decrypts with the host SSH key

- The re-key must be run by a key that can currently decrypt, so the user runs
  `sops updatekeys` themselves.
- The machine gains a proper machine identity; onboarding docs in
  `secrets/README.md` must now describe two recipient KINDS (per-user keys and
  per-host keys) rather than one.
- The alex key stays a recipient, so editing secrets by hand is unchanged.
