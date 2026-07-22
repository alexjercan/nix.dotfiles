# Secrets (sops-nix)

Encrypted-in-repo secrets for this config. Values are encrypted with
[sops](https://github.com/getsops/sops) to [age](https://age-encryption.org)
recipients; the recipient policy lives in `../.sops.yaml`. Decryption happens at
home-manager activation via the `sops-nix.service` user service, into
`$XDG_RUNTIME_DIR` (never the Nix store). See
`../tasks/20260722-113105/RECOMMENDATION.md` for the why.

Files here:

- `scufris.env` - sops dotenv for scufris's `environmentFile`. Currently holds a
  DUMMY `SCUFRIS_OPENAI_API_KEY` (PoC); swap in the real value before relying on
  it (see "Edit a secret").

## The model: one dedicated age key per machine

Each machine has its OWN passwordless age key at `~/.config/sops/age/keys.txt`
(mode 600), generated with `age-keygen`. It is NOT in this repo and NOT in the
Nix store - cloning the config does not bring it. A secret can only be decrypted
by a machine whose age PUBLIC key is a recipient in `../.sops.yaml`. This is a
per-USER key, not a host SSH key, so it works the same on NixOS and on
standalone home-manager (e.g. non-NixOS Ubuntu).

`sops`/`age` are not installed globally here; run them via nix:
`nix shell nixpkgs#sops -c sops ...` and `nix shell nixpkgs#age -c age-keygen ...`
(or add them to a dev shell / your packages). Run the `sops` commands below from
the REPO ROOT - the secret paths (`secrets/scufris.env`) are repo-root-relative,
matching the `path_regex` in `.sops.yaml`.

## Onboarding a NEW machine

You cannot bootstrap a machine from itself: a brand-new key cannot read existing
secrets until an EXISTING recipient re-encrypts them to include it. So you need
one already-trusted machine (or a backup of an existing key) on hand.

1. On the NEW machine, generate its key and print its PUBLIC half:

   ```bash
   mkdir -p ~/.config/sops/age
   nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt
   nix shell nixpkgs#age -c age-keygen -y ~/.config/sops/age/keys.txt   # age1... public key
   ```

   If the key file already exists, `age-keygen -o` refuses to overwrite it (exits
   with "file exists") and leaves it intact - reuse the existing key, print its
   public half with `-y`, and do NOT `rm` it: deleting it locks this machine out
   of everything encrypted only to that key.

2. On an EXISTING machine that can already decrypt, add that public key to
   `../.sops.yaml` as a new anchor and list it in the relevant `age:` group:

   ```yaml
   keys:
     - &alex_nixos  age1mlm56pcyksalqcgdp7gja5wzs28fp2jz8cdp8z4d3zdj2dfv2cqsca4u2g
     - &alex_ubuntu age1<the-new-machine-public-key>
   creation_rules:
     - path_regex: secrets/[^/]+\.env$
       key_groups:
         - age: [ *alex_nixos, *alex_ubuntu ]
   ```

3. Re-encrypt each secret to the new recipient set, then commit. `updatekeys`
   must be run BY a key that can currently decrypt (it re-wraps the data key);
   point `SOPS_AGE_KEY_FILE` at your existing key:

   ```bash
   SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
     nix shell nixpkgs#sops -c sops updatekeys --yes secrets/scufris.env
   git add ../.sops.yaml secrets/scufris.env && git commit -m "secrets: add <machine> recipient"
   ```

4. On the new machine: `git pull` and `home-manager switch`. Its key is now a
   recipient, so `sops-nix.service` decrypts at activation and scufris reads the
   rendered env file. `updatekeys` changes only the recipients, never the
   value - the plaintext is unchanged.

## Edit a secret (including swapping the PoC dummy for a real value)

Opens the decrypted content in `$EDITOR`, re-encrypts on save:

```bash
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  nix shell nixpkgs#sops -c sops secrets/scufris.env
```

Inspect the decrypted value without editing:

```bash
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  nix shell nixpkgs#sops -c sops decrypt --input-type dotenv --output-type dotenv secrets/scufris.env
```

## Revoking a machine

Remove its anchor from `../.sops.yaml`, re-key, and commit:

```bash
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  nix shell nixpkgs#sops -c sops updatekeys --yes secrets/scufris.env
```

`updatekeys` stops a REMOVED machine from decrypting FUTURE versions, but that
machine already saw the current value - rotate the actual secret (regenerate the
API key) if it may have been compromised.

## Key loss and backups

If the only private key that can decrypt a secret is lost, the ciphertext in
this repo is unrecoverable on its own. The real values also originate outside
the store (historically `~/.config/scufris/env`), so keep that source or a
backup of the age key somewhere safe. For resilience, consider adding a second
"backup" recipient - an age key kept offline - to `../.sops.yaml` from the start,
so no single lost key locks you out.
