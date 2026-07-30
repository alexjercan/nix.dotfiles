# Share one sops secret between the scufris user service and the root scufris-hostd unit

- STATUS: CLOSED
- PRIORITY: 90
- TAGS: nix,security,sops,scufris

## Flow State

- FLOW STEP: REVIEWING
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

- [x] Carry the WIP: the current master working tree is dirty with a broken
      draft AND with real new secret material (`SCUFRIS_HOSTD_SECRET`,
      `SCUFRIS_TELEGRAM_ALLOWED_CHAT_IDS` added to the encrypted file). Capture
      the diff, sprout the worktree, apply it there, and restore master to a
      clean tree - the plaintext of the two new variables must survive the move
      (decrypt before and after and compare).
- [x] Convert `secrets/scufris.env` to `secrets/scufris.yaml`: decrypt, derive
      the variable NAMES from the actual decrypted file (ledger:
      `read-secret-keys-not-assume`, do NOT trust nearby comments), write them
      as top-level YAML keys, encrypt with sops, `git rm` the old `.env` and
      `git add` the new file (ledger: `inputs-self-needs-tracked-file`).
- [x] Widen `.sops.yaml`'s `path_regex` to cover the new extension and add the
      host recipient anchor produced in the next step.
- [x] Add the host key as a recipient: convert `/etc/ssh/ssh_host_ed25519_key.pub`
      with `ssh-to-age`, add it as a `&host_nixos` anchor alongside
      `&alex_nixos`. AMENDED: no `sops updatekeys` was needed or run. The plan
      assumed re-keying an existing file, but the format conversion CREATES
      `secrets/scufris.yaml`, and `sops encrypt` applies the creation rule as it
      stands - so the file was born encrypted to both recipients. `updatekeys`
      is still the right command for a future recipient change and is what
      `secrets/README.md` documents. Verified the ciphertext still decrypts with
      the alex key afterwards (all four values hash-identical to before).
- [x] Import `inputs.sops-nix.nixosModules.sops` in `hosts/nixos/default.nix`
      (the `inputs` module arg is already added by the WIP) and leave
      `sops.age.sshKeyPaths` at its default (openssh is enabled and
      `/etc/ssh/ssh_host_ed25519_key` exists).
- [x] Declare the per-key secrets against the YAML file with `mode = "0400"`,
      root-owned, and `restartUnits = ["scufris-hostd.service"]` on the shared
      credential so rotating it restarts the helper. AMENDED: not one secret
      named `scufris-hostd-secret` with an explicit `key`, but one secret per
      variable, each NAMED after the variable it holds and generated with
      `lib.genAttrs` from a single `scufrisEnvVars` list. The template needs a
      placeholder per variable anyway, so the secrets had to exist regardless;
      naming them after the variable makes sops-nix's `key` default correct and
      leaves the variable name written down exactly once.
- [x] Declare `sops.templates."scufris.env"` rendering EVERY variable as
      `NAME=${config.sops.placeholder."<name>"}`, `owner = "alex"`,
      `mode = "0400"`. Each placeholder must resolve to the VALUE only - the
      ledger's `sops-dotenv-decrypts-whole-file` records a doubled
      `NAME=NAME=<value>` line from getting this wrong, so assert the rendered
      file's shape.
- [x] Point `services.scufris-hostd.secretFile` at
      `config.sops.secrets."SCUFRIS_HOSTD_SECRET".path`
      (`/run/secrets/SCUFRIS_HOSTD_SECRET`, per the naming amendment above) and
      keep `group = "scufris"`.
- [x] Add `users.groups.scufris = {}` and `"scufris"` to
      `users.users.alex.extraGroups`.
- [x] In `home/alex/default.nix`: delete the `sops` block and the
      `systemd.user.services.scufris.Unit.After = ["sops-nix.service"]` line
      (that unit no longer exists in the HM generation), and set
      `environmentFile` to the rendered path literal, with a comment naming
      `hosts/nixos/default.nix` as the declaring side and why the string is not
      a typed reference.
- [x] Restore the settings comments the WIP flattened, keeping the user's
      deliberate values: `auth_mode = "required"`,
      `agent_backend = "codex"`, `host_config_repo`, `den_path`, `auto_wake`,
      and `telegram_allowed_chat_ids` now sourced from the secret rather than
      `settings`.
- [x] Replace the pin comment in `flake.nix` for the `scufris` input: record
      that master is a DELIBERATE temporary unpin to test `scufris-hostd`, that
      the feature releases in v0.2.0, and that the pin returns then.
- [x] Update the doc surfaces the change invalidates: `secrets/README.md`
      (dotenv -> yaml, HM-activation -> system decryption at boot, the two
      derived outputs, the new host recipient and what it means for onboarding
      a machine) and any stale comment in `home/alex/default.nix`.
- [x] Run the check suite and the eval proofs below; then hand the machine-level
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
  NOT to the env file; the rendered env file covers exactly the variables the
  encrypted file holds, once each, with no doubled `NAME=NAME=`; and the two
  evaluations name the same rendered path
  (cmd: `nix build .#checks.x86_64-linux.scufris-secret-wiring`).
  AMENDED from three one-off greps: they became one `flake/checks.nix`
  derivation instead, so `nix flake check` enforces the wiring permanently
  rather than this task grepping it once. The secret path is
  `/run/secrets/SCUFRIS_HOSTD_SECRET`, not the `scufris-hostd-secret` the plan
  guessed - each secret is named after the variable it holds, so sops-nix's
  `key` default already selects the right entry.
- Exactly one encrypted file holds the shared secret, and no home-manager sops
  DECLARATION remains
  (cmd: `test ! -e secrets/scufris.env && ! grep -rnE "config\.sops|sops = \{|homeManagerModules\.sops" home/alex/default.nix flake/home-configurations.nix | grep -vE ":[0-9]+: *#"`).
  AMENDED TWICE, and the second time is the interesting one: the original grep
  was for the bare word `sops` in home/alex, which the explanatory comments the
  same plan asked for would themselves fail. Narrowing it to declaration
  syntax was not enough either - the NOTE in flake/home-configurations.nix
  explaining the module's ABSENCE names the module, and an absence-proving grep
  that cannot distinguish code from the comment documenting the absence will
  keep catching its own documentation. It now excludes comment lines.
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

All three `manual:` items above were CONFIRMED BY THE USER on 2026-07-30, after
the review reached APPROVE and before the branch landed: the rebuild and switch
were run on the machine, the helper and its socket came up as specified, and a
host-action proposal round-tripped end to end. That last one is the only proof
the two units hold the same secret VALUE - no evaluation-time check can reach
it - so it is what gated the land.

## Outcome

### What changed

`secrets/scufris.env` (sops dotenv, decrypted by home-manager into
`$XDG_RUNTIME_DIR`) became `secrets/scufris.yaml`, decrypted once by the NixOS
configuration into two derived outputs: `/run/secrets/<VAR>` per-key files (the
root helper reads `SCUFRIS_HOSTD_SECRET`) and `/run/secrets/rendered/scufris.env`
(the user service's `environmentFile`). The machine's SSH host key, converted
with `ssh-to-age`, joins my per-user key as an age recipient so the system can
decrypt at boot. `users.groups.scufris` and alex's membership in it were added -
without them the socket is unreachable regardless of the secret.

Both format and locus were forced, not chosen: `sops-install-secrets` ignores
`key` for dotenv/ini/binary and always decrypts whole-file
(`main.go:340-375`), so only a YAML source can produce the raw single-value
file `scufris-hostd --secret-file` requires; and a root unit that starts at
boot cannot read a path that only exists while alex is logged in. The
alternatives (two decryptors over one file; folding home-manager into the NixOS
config) are recorded with their tradeoffs in `DECISION.md`.

One notable addition beyond the plan: `flake/checks.nix`. The accepted cost of
the chosen architecture is a hardcoded path string spanning two evaluations,
and nothing in `nix flake check` could see a drift between them - both sides
would keep evaluating happily while the service started with no secrets at all.
The check welds that seam: it asserts the two sides name the same path, that
the helper reads the raw secret rather than the env file, that no rendered line
is a doubled `NAME=NAME=`, and that the template covers exactly the variables
the encrypted file holds (read from the ciphertext's cleartext keys - nothing
is decrypted to run it).

### Difficulties

- **The check had to be proven able to fail.** Three sabotages were run against
  the committed implementation - repointing home's `environmentFile`, aiming
  `secretFile` at the env file, deleting a variable from `scufrisEnvVars` - and
  each produced the specific intended failure. Without that, a green check
  proves only that it ran.
- **`nix flake check --no-build` does not run checks.** It evaluates them.
  The repo's documented check suite used `--no-build`, so the new check would
  have been silently inert in the very command meant to enforce it; `AGENTS.md`
  now says to use the bare form before landing.
- **An absence-proving grep kept catching its own documentation** - twice. The
  DoD grep for `sops` in `home/alex` failed against the comments explaining the
  new arrangement; narrowing it to declaration syntax then failed against the
  NOTE in `flake/home-configurations.nix` explaining why the module is absent.
  Excluding comment lines fixed it. The ledger already has
  `dod-grep-excludes-task-records` for the tasks/ tree; comments documenting an
  absence are the same shape of self-match one level down.
- **The dirty working tree held real secret material.** The WIP being carried
  contained two newly-added encrypted variables, so it could not simply be
  discarded and re-typed. Per-value SHA-256 hashes were taken before the move
  and re-checked after the carry AND after the dotenv-to-YAML conversion; all
  four matched both times.

### Self-reflection

Encoding the DoD as a flake check instead of a list of one-shot greps was the
right call and should have been the plan's instinct rather than a mid-work
improvement - the greps I wrote at plan time were, twice, subtly wrong in ways
a derivation-shaped assertion never was. The plan also guessed two concrete
names (`scufris-hostd-secret`, a `sops updatekeys` step) that reality replaced;
both were harmless, but they are the cost of naming implementation details in
a plan before reading the module that consumes them. Next time: for a task
whose whole point is that two configurations must agree, write the agreement
assertion FIRST and let it drive the naming.

## Notes

- No `sprout land` until the manual machine-level items are confirmed; the
  eval proofs cannot show that the two services agree on the secret VALUE.
- `SCUFRIS_TELEGRAM_ALLOWED_CHAT_IDS` is not really a credential but already
  lives in the encrypted file; it moves along with the rest rather than being
  split out in this task.
