# Review: Fix nix flake check 'path ...-hosts is not valid'

- VERDICT: APPROVE (round 1, out-of-context reviewer)
- BRANCH: bug/flake-check-hosts

## Summary

Root cause confirmed real and reproduced deterministically by an independent
fresh-context reviewer. `hostsDir = ../hosts` / `homeDir = ../home` path
literals were string-coerced (`"${hostsDir}/${hostName}"` and `builtins.readDir`),
copying each directory into the store as its own floating `<hash>-hosts` /
`<hash>-home` root. That root is not a GC root, so `nix-collect-garbage` reaps
it while the flake eval cache still pins the old hash; a later `nix flake check`
then fails with `error: path '...-hosts' is not valid`.

Fix: reference the directories as subpaths of the flake source
(`"${inputs.self}/hosts"`, `"${inputs.self}/home"`). They now live inside the
single flake `-source` root, which Nix re-copies from the tracked git tree on
every evaluation, so GC can no longer orphan them.

## Reproduction (both sides, by the reviewer)

- master: fresh `nix flake check` (green) -> `nix-store --delete` the floating
  `-hosts`/`-home` paths -> re-check fails with the exact reported error.
- fixed branch: same delete-then-recheck stays green; no floating `-hosts`
  root is ever created (`${inputs.self}/hosts` = `...-source/hosts`).

## Findings

- (info) `${inputs.self}/hosts` reflects only git-tracked content, whereas a
  raw path literal would include untracked/dirty files. Verified no untracked
  or gitignored files under `hosts/` or `home/` today (`.gitignore` lists only
  `tmp`), so behavior is identical. This is standard, desired flake semantics.
  Not a blocker.
- (nit, addressed) Comment wording tightened to say the flake *source root* is
  what Nix re-copies from the git tree, not the subpath itself.

## Verification

- `nix flake check --no-build` passes (exit 0).
- `nixosConfigurations = {nixos}`, `homeConfigurations = {alex}` unchanged
  (the `home/modules` dir still correctly excluded).
- Sweep: no other `../` string-coerced directory literals remain in `flake/`.
