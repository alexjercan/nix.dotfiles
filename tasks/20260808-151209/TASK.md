# Quote afk status labels

- PRIORITY: 1
- TAGS: bug, afk
- ACTIVITY: WORKING
- GATES: PLAN
- RESOLUTION: -

## Context

The afk derivation fails because ShellCheck treats two bare `done` label
arguments as SC1010 findings. Preserve output and leave unrelated dirty files
untouched. See `DECISION.md`.

## Steps

- [ ] Quote both `done` label arguments in `home/modules/scripts/afk.sh`.
- [ ] Run the afk integration test and build the home-manager activation
      package.
- [ ] Re-read the diff and record diagnosis, evidence, and reflection.

## Definition of Done

- Both landing-status calls pass `"done"` as a string (cmd: `test "$(rg -n
  '(^|[[:space:]])(line|head_line) .* "done" ' home/modules/scripts/afk.sh |
  wc -l)" -eq 2`).
- The afk integration suite passes (cmd: `bash home/modules/scripts/afk-test.sh`).
- The affected home-manager package builds (cmd: `nix build
  .#homeConfigurations.alex.activationPackage --no-link`).

## Notes

- The failing build output is the red proof for the activation package on the
  base tree.
- The deprecated `system` warning is outside this task.
