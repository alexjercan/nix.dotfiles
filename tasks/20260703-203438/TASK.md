# Make the `daily` script agent-friendly (JSON output, exit codes, help)

- STATUS: OPEN
- PRIORITY: 90
- TAGS: feature

## Goal

`daily` (home/modules/scripts/daily.nix) prints a human markdown summary and
emits confirmation/error lines on stdout mixed with data. Agents need to read
the day's state as structured data and drive the existing mutation commands
(toggle/add/remove tasks, habits, macros, notes, weight) with reliable exit
codes and clean stdout. Add a machine-readable mode and tidy the streams and
exit codes without changing the human-facing default output.

Done means:
- `daily --json` emits a single JSON object for the day (date, file, title,
  habits with done flags, today's tasks with 1-based index + done flag,
  tomorrow's tasks with index, macro totals + calories, weight) so an agent
  can read state and know which index to pass to the mutation flags.
- All confirmations ("Added...", "Toggled...") and errors ("No daily journal
  entry...") go to stderr; stdout carries only the requested data.
- Exit codes are defined and documented: 0 success, 1 missing entry/file, 2
  usage error. Argument-parsing failures exit 2 (not 1).
- The default (no `--json`) human markdown summary is unchanged.

## Steps

- [ ] Add `pkgs.jq` to `runtimeInputs` and build the `--json` output with jq
      (correct escaping) rather than hand-rolled string concatenation.
- [ ] Implement `--json`: reuse the existing title/habits/tasks/macros/weight
      parsing to produce one JSON object. Today's tasks and tomorrow's tasks
      are arrays of `{index, text, done}` / `{index, text}` with 1-based
      indices matching `--toggle-task` / `--task-remove` /
      `--task-tomorrow-remove`.
- [ ] Route every human confirmation and error message to stderr; keep the
      markdown summary and `--json` payload on stdout only.
- [ ] Define exit codes: keep `exit 1` for a missing entry file; change the
      `usage()`-then-exit paths in argument parsing to `exit 2`.
- [ ] Update `usage()` to document `--json` and the exit-code contract.
- [ ] Test against a fixture den entry: `daily --json | jq .` parses and
      reflects habits/tasks/macros/weight and indices; a mutation (e.g.
      `--toggle-task 1`) still works and prints only to stderr; a missing
      entry exits 1 with a stderr message; a bad flag exits 2.

## Notes

- Relevant file: home/modules/scripts/daily.nix (the `writeShellApplication`
  text; parsing helpers `title`/`habits`/`today_tasks`/`macros`/`weight`, the
  mutation functions, and the main dispatch block).
- Preserve `${config...}`/`${pkgs...}` nix interpolations; escape bash `$` as
  `$$` per the existing script.
- The tomorrow tasks are bullet lines (`- ...`), today's tasks are checkboxes
  (`- [ ]`/`- [x]`); index them the same way the remove/toggle functions do.
