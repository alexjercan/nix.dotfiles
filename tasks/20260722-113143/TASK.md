# Remove inert allowUnfree from the home user module

- PRIORITY: 30
- TAGS: chore, nix
- KIND: TASK
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE

## Story

`nixpkgs.config.allowUnfree = true` is set in THREE places: hosts/nixos/default.nix,
home/alex/default.nix, and flake/home-configurations.nix (the external
`import nixpkgs`). Per the LESSONS.md `hm-external-pkgs-ignores-nixpkgs-config`
lesson, the in-module one (home/alex/default.nix) is INERT because home is built
with an externally-imported pkgs. It is a trap for the next reader.

## Steps

- [x] Confirm the home-module `allowUnfree` is inert (drop it, `nix flake check`,
      verify unfree pkgs like codex/claude-code still build).
- [x] Either remove the inert line or annotate it; keep the effective one in
      flake/home-configurations.nix as the single source of truth.

## Resolution

Removed `nixpkgs.config.allowUnfree = true;` from home/alex/default.nix and
replaced it with a NOTE comment explaining it is inert (pointing to the external
import in flake/home-configurations.nix and the LESSONS entry).

Proof it was inert: after removal, `nix flake check --no-build` stays green
(it evaluates homeConfigurations.alex, which contains unfree pkgs), and
`nix eval .#homeConfigurations.alex.config.home.packages` still resolves unfree
packages (discord/brave -> "unfree-present-and-allowed"). The effective setting
remains solely on the external `import nixpkgs { config.allowUnfree = true; }`.

## Notes

- See LESSONS.md `hm-external-pkgs-ignores-nixpkgs-config` (20260721-140158).
- The host-level one is separate (system pkgs) and stays.

## Definition of Done

No Definition of Done was recorded when this task ran. The section is added on
2026-07-30 so the record satisfies the tatr v2 schema; nothing is reconstructed
after the fact.

- The work delivered and the verification the closing session ran are recorded
  in the sections above (manual: read this record).
- The task was accepted by its review (manual: read the round verdicts in
  REVIEW.md).
