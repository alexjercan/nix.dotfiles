# Secrets (sops-nix)

Encrypted-in-repo secrets for this config. Values are encrypted with
[sops](https://github.com/getsops/sops) to [age](https://age-encryption.org)
recipients; the recipient policy lives in `../.sops.yaml`. Decryption happens in
the NixOS configuration (`../hosts/nixos/default.nix`) at BOOT, into `/run`
(never the Nix store). See `../tasks/20260722-113105/RECOMMENDATION.md` for why
sops-nix, and `../tasks/20260730-190929/DECISION.md` for why decryption sits at
the system level rather than in home-manager.

Files here:

- `scufris.yaml` - one sops YAML file holding every scufris credential:
  `SCUFRIS_TELEGRAM_BOT_TOKEN`, `SCUFRIS_AUTH_PASSWORD_HASH`,
  `SCUFRIS_TELEGRAM_ALLOWED_CHAT_IDS` and `SCUFRIS_HOSTD_SECRET`.

## One file, two consumers

`SCUFRIS_HOSTD_SECRET` is shared by two units that run at different privileges,
so it must be written down exactly once:

```
secrets/scufris.yaml
        |
   sops-nix, NixOS level, keyed to this machine's SSH host key
        |
        +-- sops.secrets."<VAR>"  (one per variable, root 0400)
        |     /run/secrets/SCUFRIS_HOSTD_SECRET
        |     -> services.scufris-hostd.secretFile   (root system unit)
        |
        +-- sops.templates."scufris.env"  (alex 0400)
              /run/secrets/rendered/scufris.env
              -> programs.scufris.environmentFile    (alex user service)
```

Two consequences worth knowing before editing anything here:

- **The file is YAML, not a dotenv, and that is load-bearing.** sops-nix ignores
  `key` for dotenv/ini/binary formats and always decrypts whole-file, so a
  dotenv cannot yield the raw single-value file `scufris-hostd` needs
  (`--secret-file` is read whole and stripped as the secret itself). Only a
  yaml/json source supports per-key extraction and `sops.placeholder`.
- **home-manager names the rendered path as a literal string**, because it is a
  standalone configuration and cannot read the NixOS `config`. `flake/checks.nix`
  asserts the two sides still agree, and that every variable in this file is
  rendered into the env file, so a drift fails `nix flake check`.

Adding a variable therefore means: `sops secrets/scufris.yaml` to add it, and
add its name to `scufrisEnvVars` in `../hosts/nixos/default.nix`. The check
fails if you do only one of the two.

## The model: two KINDS of age recipient

- A per-USER key at `~/.config/sops/age/keys.txt` (mode 600), generated with
  `age-keygen`. This is what decrypts when I edit a secret by hand. It is NOT in
  this repo and NOT in the Nix store - cloning the config does not bring it.
- A per-HOST key, derived from the machine's SSH host key with `ssh-to-age`.
  This is what the NixOS sops-nix module decrypts with at activation and at
  boot (`sops.age.sshKeyPaths` defaults to `/etc/ssh/ssh_host_ed25519_key`),
  BEFORE any user session exists.

A secret a system service must read needs BOTH: the user key so I can edit it,
the host key so the machine can start. A secret encrypted only to a user key
leaves `scufris-hostd` unable to start - it is fail-closed by design.

`sops`/`age`/`ssh-to-age` are not installed globally here; run them via nix:
`nix shell nixpkgs#sops -c sops ...`. Run the `sops` commands below from the
REPO ROOT - the secret paths (`secrets/scufris.yaml`) are repo-root-relative,
matching the `path_regex` in `.sops.yaml`.

## Onboarding a NEW machine

You cannot bootstrap a machine from itself: a brand-new key cannot read existing
secrets until an EXISTING recipient re-encrypts them to include it. So you need
one already-trusted machine (or a backup of an existing key) on hand.

1. On the NEW machine, get both public keys:

   ```bash
   # the per-user key
   mkdir -p ~/.config/sops/age
   nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt
   nix shell nixpkgs#age -c age-keygen -y ~/.config/sops/age/keys.txt   # age1...

   # the per-host key (NixOS machines that run system-level secrets)
   nix shell nixpkgs#ssh-to-age -c ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub
   ```

   If the user key file already exists, `age-keygen -o` refuses to overwrite it
   (exits with "file exists") and leaves it intact - reuse it, print its public
   half with `-y`, and do NOT `rm` it: deleting it locks this machine out of
   everything encrypted only to that key.

2. On an EXISTING machine that can already decrypt, add those public keys to
   `../.sops.yaml` as new anchors and list them in the relevant `age:` group:

   ```yaml
   keys:
     - &alex_nixos   age1mlm56pcyksalqcgdp7gja5wzs28fp2jz8cdp8z4d3zdj2dfv2cqsca4u2g
     - &host_nixos   age1msnpfzujk0j7muvze6qxvrsucwtylala0j2hhqa0n57am83qk5fqev62c2
     - &alex_ubuntu  age1<the-new-machine-user-key>
   creation_rules:
     - path_regex: secrets/[^/]+\.(env|yaml)$
       key_groups:
         - age: [ *alex_nixos, *host_nixos, *alex_ubuntu ]
   ```

3. Re-encrypt each secret to the new recipient set, then commit. `updatekeys`
   must be run BY a key that can currently decrypt (it re-wraps the data key);
   point `SOPS_AGE_KEY_FILE` at your existing key:

   ```bash
   SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
     nix shell nixpkgs#sops -c sops updatekeys --yes secrets/scufris.yaml
   git add ../.sops.yaml secrets/scufris.yaml && git commit -m "secrets: add <machine> recipient"
   ```

4. On the new machine: `git pull`, then `nixos-rebuild switch` (which decrypts)
   and `home-manager switch`. `updatekeys` changes only the recipients, never
   the value - the plaintext is unchanged.

   A NON-NixOS machine has no system-level sops-nix, so it has no
   `/run/secrets`. Such a host needs its own home-manager `sops` block
   rendering the env file into `$XDG_RUNTIME_DIR` and a matching
   `environmentFile`; it cannot run `scufris-hostd` at all, that module being
   NixOS-only.

## Edit a secret

Opens the decrypted content in `$EDITOR`, re-encrypts on save:

```bash
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  nix shell nixpkgs#sops -c sops secrets/scufris.yaml
```

Inspect the decrypted values without editing:

```bash
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  nix shell nixpkgs#sops -c sops decrypt secrets/scufris.yaml
```

Generate the dashboard password hash (the scrypt hash is what gets stored, never
the password):

```bash
scufris hash-password
```

## Revoking a machine

Remove its anchor from `../.sops.yaml`, re-key, and commit:

```bash
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  nix shell nixpkgs#sops -c sops updatekeys --yes secrets/scufris.yaml
```

`updatekeys` stops a REMOVED machine from decrypting FUTURE versions, but that
machine already saw the current value - rotate the actual secret (regenerate the
API key, re-run `scufris hash-password`, mint a new `SCUFRIS_HOSTD_SECRET`) if it
may have been compromised. Rotating `SCUFRIS_HOSTD_SECRET` restarts
`scufris-hostd` automatically (`restartUnits`), but the app is a user service:
run `home-manager switch` too, or the two sides hold different secrets and every
host action is refused.

## Key loss and backups

If the only private key that can decrypt a secret is lost, the ciphertext in
this repo is unrecoverable on its own. Note that a host key is lost by
REINSTALLING the machine, not just by deleting a file - keep the per-user key
backed up somewhere safe so a rebuilt host can be re-keyed from it. For
resilience, consider adding a second "backup" recipient - an age key kept
offline - to `../.sops.yaml`, so no single lost key locks you out.
