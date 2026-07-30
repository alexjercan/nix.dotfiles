# Share one sops secret between the scufris user service and the root scufris-hostd unit

- STATUS: OPEN
- PRIORITY: 90
- TAGS: nix,security,sops,scufris

## Flow State

- FLOW STEP: PLANNED
- PLAN STATUS: APPROVED

## Story

As the operator of this machine, I want ONE encrypted source of truth to feed
both the scufris home-manager user service (`environmentFile`, a full
`KEY=value` env file) and the root `services.scufris-hostd` unit
(`secretFile`, a RAW single-value file), so the shared socket credential is
written in exactly one place and the two services cannot drift apart.

## Problem

The uncommitted WIP on master wires `services.scufris-hostd.secretFile` to
`config.sops.secrets."scufris-env".path` from `hosts/nixos/default.nix`. Four
independent reasons that cannot work:

1. `config.sops` does not exist in the NixOS eval - only
   `inputs.sops-nix.homeManagerModules.sops` is imported
   (`flake/home-configurations.nix:39`). Evaluating the host config fails with
   `error: attribute 'sops' missing ... Did you mean jobs?`.
2. Home-manager here is STANDALONE (`flake.homeConfigurations`, its own
   `import nixpkgs`), so the host config and `home/alex` are separate
   evaluations that can never share a `config` value.
3. HM sops-nix decrypts into `$XDG_RUNTIME_DIR` at home-manager ACTIVATION.
   `scufris-hostd.service` is `wantedBy = ["multi-user.target"]` and starts at
   boot, before any user session exists; `/run/user/1000` is absent whenever
   alex is logged out (no lingering). A fail-closed root unit pointed at that
   path fails at every boot.
4. Format mismatch: `scufris/hostd/main.py:59` reads the WHOLE `--secret-file`
   and `.strip()`s it as the secret. The dotenv is a multi-line `KEY=value`
   blob, which can never equal what the app sends as `SCUFRIS_HOSTD_SECRET`.
   And per the ledger's `sops-dotenv-decrypts-whole-file`, confirmed again in
   `sops-install-secrets/main.go:340-375`: for `Binary|Dotenv|Ini` the secret's
   value is always the entire file and `key` is IGNORED - so a second secret
   with `key = "SCUFRIS_HOSTD_SECRET"` against the same `.env` cannot extract
   one variable either.

Two supporting gaps: `users.groups.scufris` does not exist and
`users.users.alex.extraGroups` (`hosts/nixos/default.nix:176`) does not include
it, so the user service could never reach the root helper's 0750 socket dir.

## Decisions

See `DECISION.md` (ACCEPTED, confirmed by the user at the plan gate):

- D1: system-level sops-nix is the SOLE decryptor; HM consumes the rendered
  path as a literal string.
- D2: the system decrypts with the host SSH ed25519 key converted to age; the
  secret is re-keyed to that recipient.

Forced consequence of both, not a fork: `secrets/scufris.env` must become a
sops YAML file, because per-key extraction (D1's raw hostd secret) is
impossible in dotenv format.

## Steps

- [ ] Carry the WIP: the current master working tree is dirty with a broken
      draft AND with real new secret material (`SCUFRIS_HOSTD_SECRET`,
      `SCUFRIS_TELEGRAM_ALLOWED_CHAT_IDS` added to the encrypted file). Capture
      the diff, sprout the worktree, apply it there, and restore master to a
      clean tree - the plaintext of the two new variables must survive the move
      (decrypt before and after and compare).
- [ ] Convert `secrets/scufris.env` to `secrets/scufris.yaml`: decrypt, derive
      the variable NAMES from the actual decrypted file (ledger:
      `read-secret-keys-not-assume`, do NOT trust nearby comments), write them
      as top-level YAML keys, encrypt with sops, `git rm` the old `.env` and
      `git add` the new file (ledger: `inputs-self-needs-tracked-file`).
- [ ] Widen `.sops.yaml`'s `path_regex` to cover the new extension and add the
      host recipient anchor produced in the next step.
- [ ] Add the host key as a recipient: convert `/etc/ssh/ssh_host_ed25519_key.pub`
      with `ssh-to-age`, add it as a `&host_nixos` anchor alongside
      `&alex_nixos`, and re-key with `sops updatekeys`. Verify the ciphertext
      still decrypts with the alex key afterwards.
- [ ] Import `inputs.sops-nix.nixosModules.sops` in `hosts/nixos/default.nix`
      (the `inputs` module arg is already added by the WIP) and leave
      `sops.age.sshKeyPaths` at its default (openssh is enabled and
      `/etc/ssh/ssh_host_ed25519_key` exists).
- [ ] Declare `sops.secrets."scufris-hostd-secret"` against the YAML file with
      `key = "SCUFRIS_HOSTD_SECRET"`, `mode = "0400"`, root-owned, and
      `restartUnits = ["scufris-hostd.service"]` so rotating the secret
      restarts the helper.
- [ ] Declare `sops.templates."scufris.env"` rendering EVERY variable as
      `NAME=${config.sops.placeholder."<name>"}`, `owner = "alex"`,
      `mode = "0400"`. Each placeholder must resolve to the VALUE only - the
      ledger's `sops-dotenv-decrypts-whole-file` records a doubled
      `NAME=NAME=<value>` line from getting this wrong, so assert the rendered
      file's shape.
- [ ] Point `services.scufris-hostd.secretFile` at
      `config.sops.secrets."scufris-hostd-secret".path` and keep
      `group = "scufris"`.
- [ ] Add `users.groups.scufris = {}` and `"scufris"` to
      `users.users.alex.extraGroups`.
- [ ] In `home/alex/default.nix`: delete the `sops` block and the
      `systemd.user.services.scufris.Unit.After = ["sops-nix.service"]` line
      (that unit no longer exists in the HM generation), and set
      `environmentFile` to the rendered path literal, with a comment naming
      `hosts/nixos/default.nix` as the declaring side and why the string is not
      a typed reference.
- [ ] Restore the settings comments the WIP flattened, keeping the user's
      deliberate values: `auth_mode = "required"`,
      `agent_backend = "codex"`, `host_config_repo`, `den_path`, `auto_wake`,
      and `telegram_allowed_chat_ids` now sourced from the secret rather than
      `settings`.
- [ ] Replace the pin comment in `flake.nix` for the `scufris` input: record
      that master is a DELIBERATE temporary unpin to test `scufris-hostd`, that
      the feature releases in v0.2.0, and that the pin returns then.
- [ ] Update the doc surfaces the change invalidates: `secrets/README.md`
      (dotenv -> yaml, HM-activation -> system decryption at boot, the two
      derived outputs, the new host recipient and what it means for onboarding
      a machine) and any stale comment in `home/alex/default.nix`.
- [ ] Run the check suite and the eval proofs below; then hand the machine-level
      verification (rebuild, switch, socket, dashboard) to the user as the
      manual DoD items.

## Definition of Done

- The NixOS config evaluates, which is the direct regression for the current
  failure (cmd: `nix eval .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath`).
- The home config still evaluates with the sops block removed
  (cmd: `nix eval .#homeConfigurations.alex.activationPackage.drvPath`).
- Flake evaluation and repo conformance pass
  (cmd: `nix flake check --no-build && tatr check && tatr check --ledger LESSONS.md`).
- The sprout CLI suite is unaffected
  (cmd: `bash home/modules/scripts/sprout-test.sh`).
- The hostd unit's `--secret-file` argument resolves to the per-key secret and
  NOT to the env file
  (cmd: `nix eval --raw .#nixosConfigurations.nixos.config.systemd.services.scufris-hostd.serviceConfig.ExecStart | grep -F -- "--secret-file /run/secrets/scufris-hostd-secret"`).
- Exactly one encrypted file holds the shared secret, and no `.env` secret or
  HM sops declaration remains
  (cmd: `test ! -e secrets/scufris.env && ! grep -rn "sops" home/alex/default.nix`).
- The rendered template declares every variable the old dotenv held, once each,
  with no doubled `NAME=NAME=` (cmd: a scripted check over
  `config.sops.templates."scufris.env".content` asserting one `NAME=` prefix
  per line and the full key set).
- Both age recipients can decrypt the secret after re-keying
  (manual: `sops decrypt secrets/scufris.yaml` with the alex key, and
  `sudo sops decrypt` with the host key).
- On the real machine: `nixos-rebuild switch` brings `scufris-hostd.service` to
  active, `/run/scufris-hostd/hostd.sock` exists as `root:scufris` 0660, and
  `/run/secrets/rendered/scufris.env` is `alex` 0400
  (manual: user runs the rebuild and reports).
- After `home-manager switch`, the dashboard authenticates and a host action
  proposal round-trips through the helper - the end-to-end proof that both
  services hold the SAME secret (manual: user drives one proposal and
  approves it).

## Notes

- No `sprout land` until the manual machine-level items are confirmed; the
  eval proofs cannot show that the two services agree on the secret VALUE.
- `SCUFRIS_TELEGRAM_ALLOWED_CHAT_IDS` is not really a credential but already
  lives in the encrypted file; it moves along with the rest rather than being
  split out in this task.
