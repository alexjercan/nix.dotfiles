# Refactor home.packages into topical modules

- STATUS: OPEN
- PRIORITY: 20
- TAGS: chore,nix,refactor

## Story

home/alex/default.nix has one big flat `home.packages` list (davinci-resolve next
to ripgrep next to wesnoth). Everything ELSE in the repo is modularized under
home/modules/, so this list is the odd one out. Split it into topical modules
(e.g. media, dev, desktop) to match the repo's style.

## Steps

- [ ] Investigate a sensible grouping (media / dev-tools / desktop / cli) and
      whether some packages already belong to an existing module.
- [ ] Move packages into home/modules/<group>/default.nix files, imported from
      home/alex/default.nix.
- [ ] `nix flake check` green; built home closure lists the same package set as
      before (diff the paths).

## Notes

- Pure refactor: the resulting package set must be identical - prove it by
  diffing the closure before/after.
