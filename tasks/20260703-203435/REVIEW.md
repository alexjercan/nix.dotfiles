# Review: Make the `today` script agent-friendly

- TASK: 20260703-203435
- BRANCH: agent-daily-today
- ROUND: 1
- VERDICT: APPROVE

## Summary

Reviewed the diff to `home/modules/scripts/today.nix` against the task's
"done" criteria. All criteria are met and verified by a real derivation build
(shellcheck passes at build time) plus functional runs against a fixture den.
The change is focused, preserves the interactive default, and fixes a latent
rendering bug found along the way.

## Findings

### [info] Latent `$$` bug fixed, not just worked around
`$${DEN_PATH%/}` rendered to literal `$${...}` (bash `$$` = PID), so passing an
explicit DEN-PATH was already broken on master. The fix (`''${DEN_PATH%/}`) is
correct and verified by rebuild. Good catch to fix rather than replicate.

### [low] `--create` + `--path` precedence is silent
If both flags are given, `--path` wins (checked first) and nothing is created.
This is a sensible default and not worth an error, but it is undocumented.
Acceptable as-is; a one-line note could be added if desired. Not blocking.

### [low, out of scope] Carry-over placement is pre-existing
`templator` appends a fresh `Today` block at EOF rather than merging into an
existing `Today` section, so an entry can contain two `Today` markers
depending on the template. This behavior is unchanged by this task. It matters
for how `daily` parses `Today` tasks, so it is flagged for the `daily` task
(20260703-203438) to use a realistic fixture and, if the duplication is real
against the production template, filed as a separate follow-up rather than
widened into this branch.

## Verification observed

- Real build via `lib.evalModules` + `writeShellApplication`: clean (==
  shellcheck pass with strict defaults).
- `--path`: prints path, does not create. `--create`: prints path, creates,
  idempotent, exit 0. First entry with no yesterday: exit 0 + stderr warning.
  Missing template: exit 1. Unknown flag: exit 2. No-flag default: opens
  `$EDITOR`.

## Verdict

APPROVE. The low findings are non-blocking; the out-of-scope one is handed to
the next task rather than fixed here.
