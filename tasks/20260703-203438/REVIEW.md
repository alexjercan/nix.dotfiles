# Review: Make the `daily` script agent-friendly

- TASK: 20260703-203438
- BRANCH: agent-daily-today
- ROUND: 1
- VERDICT: APPROVE

## Summary

Reviewed the diff to `home/modules/scripts/daily.nix`. All "done" criteria are
met and verified against a real derivation build (shellcheck clean) plus
functional runs on a fixture den. `--json` output is correct and complete, the
human markdown default is byte-for-byte unchanged, streams and exit codes are
tidy. Approve.

## Findings

### [info] Shared macros path removes divergence + a /tmp write
Refactoring to `macros_csv`/`macros_values` means the human and JSON macro
totals come from one code path, and the totals no longer go through
`/tmp/macros.csv`. Good simplification.

### [low] JSON numbers keep source precision (e.g. `16.00`)
`--argjson protein "16.00"` yields `16.00` in the output. This is valid JSON
(equal to `16`) and parses everywhere; not worth a `tonumber` normalization
pass. Non-blocking.

### [low] `--json` + a mutation flag: mutation wins silently
`daily --json --toggle-task 1` runs the toggle (the dispatch checks mutation
modes before the default/JSON branch) and ignores `--json`. Sensible
precedence, undocumented. Non-blocking; the skill docs should show them used
separately.

### [low, cross-cutting] Two `Today` markers can hide carried-over tasks
`today`'s `templator` appends a fresh `Today` block at EOF, while
`daily --task-entry` and `today_tasks`/`run_json` operate on the FIRST `Today`
marker. If the production template also contains a `Today` line under Tasks,
carried-over and manually-added tasks live in different blocks and `--json`
would only report one. This is pre-existing structure, not introduced here,
and depends on the real `Templates/daily.md` (not available in this
environment). Flagged as a follow-up to confirm against the real template
rather than fixed speculatively on this branch.

## Verification observed

- Real build via `lib.evalModules` + `writeShellApplication`: clean.
- `--json` valid and reflects habits/tasks/tomorrow/macros/weight with 1-based
  indices; `--toggle-task 1` mutates, prints only to stderr, next `--json`
  shows the flip; empty macros -> zeros, unlogged weight -> null; missing entry
  exits 1 (stderr); unknown flag exits 2; default markdown unchanged.

## Verdict

APPROVE. Low findings are non-blocking; the cross-cutting one is handed to a
follow-up task rather than widened into this branch.
