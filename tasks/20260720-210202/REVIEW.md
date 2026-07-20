# Review: swap den scripts to the packaged today CLI (20260720-210202)

- VERDICT: APPROVE
- ROUNDS: 1 (out-of-context reviewer)

## Summary

Swap the old `today` + `daily` bash scripts for the packaged `today` CLI (flake
input + overlay + home.packages), delete the old modules, and consolidate the
agent skills into a single rewritten `today` skill. Reviewer cross-checked every
documented command against the running binary; APPROVE, no blockers.

## Verified by the reviewer

- Nix wiring correct: `today` input mirrors `tatr`; `inputs.today.overlays.default`
  placed in the home overlays; `overlays.default` evaluates to a lambda and
  `pkgs.today` builds. `{pkgs, ...}:` signature right; `home.sessionVariables.DEN_PATH`
  is the correct HM option and resolves to `/home/alex/personal/the-den`; absolute
  path is unambiguous and DEN_PATH is sufficient (--den -> $DEN_PATH -> default).
- Removal complete: grep of home/ hosts/ flake/ found no refs to `config.today`/
  `config.daily`, the deleted imports, or the `daily` command/skill (only the two
  intentional "replaced the old scripts" prose notes remain). `skills/daily/`
  git-removed.
- Skill accuracy: every documented command (path/create/show[--json], task
  add|done|rm[--tomorrow], habit list|toggle, weight log/trend, macros add/agg,
  note add|list[--tag], -N offset) matches the real binary; the `show --json`
  object matches key-for-key; behavior claims (carry-forward, `[ ]`/`[x]`-only
  tasks with `[~]` skipped, day-scoped note list, single-word tag, Atwater
  calories) confirmed against source; exit codes verified. Description frontmatter
  is a solid trigger surface.
- Gates green: `nix flake check --no-build` passes; `tatr check` and
  `tatr check --ledger LESSONS.md` both rc 0.

## Findings (nits, not actioned)

- [nit] The skill does not cover den TEMPLATE authoring requirements (h3 emoji
  headers, Today/Tomorrow inside Notes). Out of scope: the skill documents
  consuming the CLI, and the real den already has a valid template.
- [nit] `daily -w` PNG plot and `home-manager switch` correctly deferred.

## Proof

`nix flake check --no-build`: all checks passed. `tatr check` / `--ledger`: rc 0.
`nix build github:alexjercan/today#today` builds; packaged binary smoke-tested end
to end. `home-manager switch` is the user's manual activation step (deferred).
