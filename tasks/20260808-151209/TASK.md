# Quote afk status labels

- PRIORITY: 1
- TAGS: bug, afk
- ACTIVITY: COMPOUNDING
- GATES: PLAN REVIEW RETRO
- RESOLUTION: DONE

## Context

The afk derivation fails because ShellCheck treats two bare `done` label
arguments as SC1010 findings. Preserve output and leave unrelated dirty files
untouched. See `DECISION.md`.

## Steps

- [x] Quote both `done` label arguments in `home/modules/scripts/afk.sh`.
- [x] Run the afk integration test and build the home-manager activation
      package.
- [x] Re-read the diff and record diagnosis, evidence, and reflection.

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

## Close-out

What/why: quoted the two `done` status labels so ShellCheck parses them as
ordinary arguments. Output and control flow remain unchanged.

Alternatives: renaming the label would change output; suppressing SC1010 would
hide valid ambiguity. Both add cost without benefit.

Diagnosis: the Nix builder runs ShellCheck with warnings as failures. Bare
`done` is a shell keyword, even where it was intended as a function argument.

Evidence: the source-shape proof failed before the edit and passed after it.
`afk-test.sh` passed 17 tests. The alex activation package built successfully,
including the afk derivation.

Reflection: use quotes for display labels that are shell grammar words. The
existing integration tests cover behavior; the derivation build covers static
analysis, so no test fixture change was needed.
