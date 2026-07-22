# Encrypted secrets management: sops-nix vs agenix

Research artifact for task 20260722-113105. Learn-and-document first; the
recommendation is at the bottom. Nothing in the repo changes because of this
doc - adoption is a separate, opt-in step.

## The problem, grounded in this repo

- The ONLY real secret today is scufris's environment file:
  `home/alex/default.nix` sets `programs.scufris.environmentFile =
  "${config.home.homeDirectory}/.config/scufris/env"`, a plaintext `KEY=value`
  file (SCUFRIS_OPENAI_API_KEY etc.) kept deliberately OUTSIDE the Nix store.
- scufris runs as a home-manager systemd USER service (`programs.scufris` lives
  in the home-manager config, not a NixOS module), so this is true on both
  machines.
- Two deployment targets with different key material:
  - NixOS host (`hosts/nixos/`): has host SSH keys
    (`/etc/ssh/ssh_host_ed25519_key`) available to system activation.
  - Standalone home-manager on a non-NixOS Ubuntu box: built via
    `inputs.home-manager.lib.homeManagerConfiguration` in
    `flake/home-configurations.nix`. No host SSH key is guaranteed; only the
    user's own key material exists.
- What is missing today: nothing is encrypted in the repo, and there is no
  key-rotation / second-machine story.

The two constraints that actually decide this: (a) the consumer is an
`environmentFile` (a `KEY=value` file) read by a home-manager user service, and
(b) the hardest target is standalone home-manager where there is no host key.

## How each tool works (facts)

### agenix (ryantm/agenix)

- Encrypts each secret as its own `<name>.age` file. Recipients are age
  identities or SSH PUBLIC keys, declared in a pure-Nix `secrets.nix`:
  `"scufris-env.age".publicKeys = [ user host ];`.
- Decrypts with a private identity. On NixOS the module defaults to the host
  keys in `config.services.openssh.hostKeys` (rsa + ed25519). The Home Manager
  module has NO default: `age.identityPaths` is a REQUIRED option, e.g.
  `age.identityPaths = [ "~/.ssh/id_ed25519" ]` or an age key file.
- One opaque file per secret; NO templating (cannot assemble one file from
  several secrets).
- No `ssh-agent` support, so the decryption identity must be passwordless for
  non-interactive activation.
- Decrypts to `/run/agenix` (NixOS) or, in the HM module, `$XDG_RUNTIME_DIR/agenix`
  on Linux by default (configurable), via an activation step.
- Mental model is small: one file per secret, one Nix list of recipients.

### sops-nix (Mic92/sops-nix)

- Wraps Mozilla SOPS. A secret file is structured (yaml / json / **dotenv** /
  ini / binary) and SOPS encrypts the VALUES while leaving keys and structure
  in cleartext, so git diffs stay readable. Recipients are age (or PGP, or
  SSH-via-`ssh-to-age`, or cloud KMS / Vault) listed in `.sops.yaml` creation
  rules.
- Home Manager module key options: `sops.age.keyFile` (a passwordless age key,
  e.g. `~/.config/sops/age/keys.txt`) or `sops.age.sshKeyPaths` (convert a
  passwordless SSH ed25519 key with `ssh-to-age`). Same passwordless
  requirement as agenix.
- Secret file `format` is per-secret or `sops.defaultSopsFormat`. **dotenv**
  format matches an `environmentFile` exactly.
- TEMPLATES: `sops.templates."name".content` with
  `${config.sops.placeholder.secret}` renders a combined file from several
  secrets at activation - a first-class way to build an env file.
- Home Manager runtime: decrypts via a `sops-nix.service` systemd USER service
  into the non-persistent `$XDG_RUNTIME_DIR/secrets.d`, symlinked at
  `~/.config/sops-nix/secrets`. Any user service that consumes a secret must
  order after it: `systemd.user.services.<svc>.Unit.After = [ "sops-nix.service" ]`.
- Rotation: edit `.sops.yaml` recipients and `sops updatekeys`. Scales to many
  secrets and to KMS/Vault if this ever leaves a single-user setup.
- More concepts (`.sops.yaml`, formats, placeholders, templates, the user
  service ordering) but more capable.

## Side-by-side for THIS repo

| Axis | agenix | sops-nix |
| --- | --- | --- |
| Encrypt-at-rest in git | yes, whole-file `.age` | yes, per-value (readable diffs) |
| Home Manager module | yes (`age.identityPaths` required) | yes (`sops.age.keyFile`/`sshKeyPaths`) |
| Standalone HM on non-NixOS | yes, with a user identity | yes, with a user age key |
| Fit to `environmentFile` (KEY=value) | store the env file as ONE blob, point `environmentFile` at the decrypted path | native `dotenv` format OR a template renders the env file |
| Combining several secrets into one file | not supported | templates |
| Runtime wiring for scufris | activation-step decrypt, path is stable | needs `Unit.After = [ "sops-nix.service" ]` on the scufris user service |
| Key policy for N machines | `secrets.nix` publicKeys list + rekey | `.sops.yaml` path rules + `sops updatekeys` |
| Concepts to learn | few | more |
| Growth room (KMS/Vault, many secrets) | limited | broad |

### The key-material question (the standalone-HM constraint)

Both tools hit the same wall: a home-manager user service activates
non-interactively, and neither tool supports `ssh-agent`, so the decryption
identity must be PASSWORDLESS. The user's daily `~/.ssh/id_ed25519` is usually
passphrase-protected, so pointing either tool straight at it is fragile.

The clean answer for BOTH tools, and the thing that makes NixOS and Ubuntu
behave identically, is a DEDICATED passwordless age key per machine:

- `age-keygen -o ~/.config/sops/age/keys.txt` on each machine (kept out of the
  repo and out of the store, exactly like today's env file).
- List each machine's age PUBLIC key as a recipient (`.sops.yaml` for sops-nix,
  `secrets.nix` for agenix).
- Adding a second machine = generate its key, add its public key as a
  recipient, re-encrypt. THAT is the rotation / second-machine story the task
  asks for, and it does not depend on a host SSH key existing.

Once you go dedicated-age-key, the key-management stories are essentially a
tie. The differentiators are the env-file fit and the recipient-policy
ergonomics, not the keys.

## Recommendation

**Adopt sops-nix, with a dedicated passwordless age key per machine.** This is
a close call and agenix would not be wrong, but sops-nix wins on the axes that
match this repo's actual shape:

1. **Native fit to the one thing we actually have.** The secret is an
   `environmentFile`. sops-nix's `dotenv` format (or a template) maps onto it
   directly: encrypt the current `~/.config/scufris/env` as a sops dotenv file,
   decrypt it to `~/.config/sops-nix/secrets/scufris-env`, and point
   `programs.scufris.environmentFile` at that path. The CONSUMER interface does
   not change - the file just moves from plaintext-outside-store to
   encrypted-in-repo / decrypted-at-runtime-outside-store.
2. **One key policy that works the same on NixOS and Ubuntu.** `.sops.yaml`
   with each machine's age public key as a recipient is a declarative,
   path-scoped policy that scales cleanly if more secrets ever appear, and it
   sidesteps the no-host-key problem on the Ubuntu box uniformly.
3. **Readable diffs.** Per-value encryption keeps key names and file structure
   visible in git, which suits the review-heavy flow this repo runs.
4. **Room to grow** (templates, KMS/Vault) at no cost today.

The price paid over agenix is real but small: more concepts, and the scufris
user service must be ordered `After = [ "sops-nix.service" ]`. Given scufris is
already a home-manager user service we control, that is a one-line addition.

**Choose agenix instead if** you decide minimal-concepts-for-a-beginner
outweighs the env-file fit: for a single opaque blob consumed by one service,
agenix's one-file-per-secret model with a pure-Nix `secrets.nix` is genuinely
simpler, and the migration would be just as cheap. Note too that agenix's
"`age.identityPaths` required, no default" (above) is NOT a real strike against
it once you commit to a dedicated age key: both tools then point at the same
named key file, so the requirement is symmetric - do not over-weight it. The
recommendation is
sops-nix on balance, not by a landslide - either is a defensible adoption.

**Either way, keep the current `environmentFile`-outside-store pattern working
until a PoC proves the replacement** (per the task's own note).

## If adopted: proof-of-concept shape (scufris env, sops-nix)

Not done here - this is the plan the PoC task would follow.

1. `age-keygen -o ~/.config/sops/age/keys.txt` on the NixOS host; record its
   public key. (Repeat on Ubuntu when that machine is set up.)
2. Add `inputs.sops-nix` to `flake.nix` and its home-manager module to
   `flake/home-configurations.nix` modules list.
3. Add `.sops.yaml` at the repo root with a creation rule listing the age
   public key(s) as recipients for `secrets/scufris.env`.
4. `sops secrets/scufris.env` (dotenv format), paste the current
   `SCUFRIS_*` values; commit the ENCRYPTED file.
5. In `home/alex/default.nix`: set `sops.age.keyFile`, declare the secret with
   `format = "dotenv"`, add
   `systemd.user.services.<scufris-unit>.Unit.After = [ "sops-nix.service" ]`,
   and repoint `programs.scufris.environmentFile` at the decrypted path.
6. Verify: `nix flake check --no-build`; rebuild home-manager; confirm scufris
   starts and reads the key. Keep the old plaintext env file until this is
   proven, then remove it.

Open risks the PoC must resolve: the exact scufris systemd USER unit name (to
order after `sops-nix.service`), and confirming the decrypted-secret path is
readable by the service at start on a non-persistent `$XDG_RUNTIME_DIR`.

## Sources

- Comparison of secret managing schemes - NixOS Wiki:
  https://wiki.nixos.org/wiki/Comparison_of_secret_managing_schemes
- ryantm/agenix (README, Home Manager module): https://github.com/ryantm/agenix
- Mic92/sops-nix (README, Home Manager + templates): https://github.com/Mic92/sops-nix
- Secret Management on NixOS with sops-nix (2025), M. Stapelberg:
  https://michael.stapelberg.ch/posts/2025-08-24-secret-management-with-sops-nix/
- Handling Secrets in NixOS: An Overview (NixOS Discourse):
  https://discourse.nixos.org/t/handling-secrets-in-nixos-an-overview-git-crypt-agenix-sops-nix-and-when-to-use-them/35462
