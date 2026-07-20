---
name: today
description: Read and edit a day's journal entry in the den with the `today` CLI - locate/create the entry, read the whole day as JSON, and add/remove/toggle tasks, habits, macros, notes and weight non-interactively. Use this skill whenever an agent needs the path to a journal entry, the structured state of a day (habits, tasks, macros, weight, notes) or needs to change it, and whenever the user mentions the daily journal, the den, habits/tasks/macros tracking, or `today`.
---

# today - Read and edit the-den journal

`today` is the single command for the-den journal: it locates/creates a day's
entry, reads it, and edits it. Bare `today` opens the entry in `$EDITOR` for
humans; every OTHER mode is a non-interactive subcommand with `--json`, so an
agent only ever calls subcommands, never the editor. Entries live under
`<den>/Daily/` named `YYYY-MM-DD-Weekday.md`. The den is resolved from `--den`,
then `$DEN_PATH`, then `~/personal/the-den`.

`today` is the sole reader/writer of the den's markdown - it replaces the old
separate `today` + `daily` bash scripts (one binary now does both).

## Commands

```bash
# Locate / create / read
today path                     # Print today's entry path, do NOT create it
today create                   # Create the entry if missing, print its path
today show                     # Human summary of the day (stdout)
today show --json              # The whole day as one JSON object (stdout)

# Tasks (Today list; --tomorrow targets the Tomorrow list)
today task add "<TEXT>"        # Add a task to Today (or --tomorrow)
today task done <INDEX>        # Toggle a Today task done/undone by index
today task rm <INDEX>          # Remove a task by index (or --tomorrow)

# Habits
today habit list               # List habits and their done state
today habit toggle "<NAME>"    # Toggle a habit (matches by name, emoji-insensitive)

# Weight
today weight <VALUE>           # Log the day's weight (e.g. 81.5 or 81.5Kg)
today weight                   # Show recent weights + net change (--days N, default 7)

# Macros
today macros add "what,protein,carbs,fat"   # Append a macros CSV row
today macros                                 # Show the aggregate (protein/carbs/fat/kcal)

# Notes
today note add "<TEXT>" [--tag <TAG>]   # Append a note (optional note :: <TAG> marker)
today note list [--tag <TAG>]           # List the day's notes, or filter by tag

# Modifiers (global; go before the subcommand)
today -N <N> <subcommand>      # Operate on the entry N days from today (may be negative)
today --den <PATH> <subcommand>   # Use a specific den dir instead of the default
today -h | --help              # Usage
```

Most subcommands take `--json`. Mutations print the updated slice (add `--json`
for machine-readable output); confirmations/errors go to stderr.

## The `today show --json` object

```json
{
  "date": "2026-07-03-Friday",
  "file": "/path/to/den/Daily/2026-07-03-Friday.md",
  "title": "Friday, July 03, 2026",
  "habits":   [{"name": "📕 Learn", "done": true}],
  "tasks":    [{"index": 1, "text": "write report", "done": false}],
  "tomorrow": [{"index": 1, "text": "plan sprint"}],
  "macros":   {"protein": 16.0, "carbs": 46.0, "fat": 11.0, "calories": 347},
  "weight":   81.5
}
```

- `weight` is a number, or `null` when none is logged.
- The 1-based `index` in `tasks` / `tomorrow` is exactly what `task done` /
  `task rm` expect.
- `macros` totals are summed from the section's CSV rows (Atwater calories).

## For agents

- Never run `today` with NO subcommand: it launches `$EDITOR` and blocks. Use a
  subcommand (`show`, `path`, `create`, `task`, ...).
- `path` and `create` write ONLY the absolute entry path to stdout, so they
  compose; every subcommand creates the entry first if it is missing EXCEPT
  `path` (which is read-only):

  ```bash
  file=$(today create)       # ensure the entry exists, capture its path
  file=$(today path)         # just resolve the path; do not create anything
  ```

- Read state, then act on it by index:

  ```bash
  today show --json | jq -r '.tasks[] | select(.done|not) | .index'  # open tasks
  today task done 1                                                   # mark #1 done
  ```

- Indices are positional and shift after a `task rm`; re-read `show --json`
  before the next index-based edit. Run one mutation per invocation.
- Read a different day with `-N`: `today -N 1 show --json` (tomorrow),
  `today -N -1 show --json` (yesterday).
- Diagnostics go to stderr; parse only stdout.

## Behavior notes

- Only `- [ ]` and `- [x]` are tasks. A non-standard checkbox marker (e.g. the
  retired `- [~]`) is skipped, not counted as a task.
- `note list` is scoped to ONE day's entry (use `-N` to pick the day); it is not
  a cross-day search. `--tag T` filters to notes carrying `note :: T`.
- Writes are validated so a logged value always reads back: `weight` must be a
  plain number, `macros add` cells must be finite numbers, a `--tag` is a single
  word.
- Entry creation is idempotent and carries yesterday's `Tomorrow` list forward
  into today's `Today` list; a first-ever entry still succeeds (warning on
  stderr).

## Exit codes

- `0` success.
- `1` runtime error (e.g. an unknown habit, a non-numeric weight, a bad macros row).
- `2` usage error (unknown option/subcommand, or a flag missing its argument).

## Guidelines

- Prefer `show --json` over scraping the human output; the markdown/summary
  output is for humans and is not a stable machine format.
- Everything targets today's entry unless you pass `-N` or `--den`.
- Do not parse anything but the single path line from `path` / `create` stdout.
