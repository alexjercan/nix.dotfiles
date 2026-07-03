---
name: daily
description: Read and edit a day's journal entry in the den with the `daily` CLI - read the whole day as JSON, and add/remove/toggle tasks, habits, macros, notes and weight non-interactively. Use this skill whenever an agent needs the structured state of a daily journal entry (habits, tasks, macros, weight) or needs to change it, and whenever the user mentions the daily journal, habits/tasks/macros tracking, or `daily`. Pairs with the `today` skill, which creates the entry file.
---

# daily - Read and edit a day's journal entry

`daily` reports and edits one day's journal entry under `<den>/Daily/`. For
agents the key mode is `--json`, which prints the whole day as a single JSON
object on stdout; every confirmation and error goes to stderr, so stdout is
always clean data. The source is `home/modules/scripts/daily.nix`. Use the
`today` skill first if the entry might not exist yet (`daily` exits 1 on a
missing entry, it does not create one).

## Commands

```bash
# Read
daily                              # Human markdown summary (stdout)
daily -j | --json                  # The whole day as one JSON object (stdout)
daily -n | --note <TAG>            # Show notes tagged `note :: <TAG>` across days
daily -w | --weight                # Render a weight-over-time plot to /tmp

# Edit today's entry (all confirmations go to stderr)
daily --task-entry <TEXT>          # Add a task to Today's Tasks
daily --toggle-task <INDEX>        # Toggle a Today task done/undone by index
daily --task-remove <INDEX>        # Remove a Today task by index
daily --task-tomorrow-entry <TEXT> # Add a task to Tomorrow
daily --task-tomorrow-remove <IDX> # Remove a Tomorrow task by index
daily --toggle-habit <HABIT>       # Toggle a habit checkbox (matches by name)
daily -m | --macros-entry <TEXT>   # Append a line to the Macros CSV section
daily -e | --notes-entry <TEXT>    # Append a line to the Notes section
daily --weight-entry <VALUE>       # Log the day's weight (e.g. 81.5 or 81.5Kg)

# Common modifiers
daily -N | --offset <N>            # Operate on the entry N days before today
daily <DEN-PATH>                   # Use a specific den dir instead of the default
daily -h | --help                  # Usage
```

## The `--json` object

`daily --json` emits exactly one object:

```json
{
  "date": "2026-07-03-Friday",
  "file": "/path/to/den/Daily/2026-07-03-Friday.md",
  "title": "Friday, July 03, 2026",
  "habits":   [{"name": "Read", "done": true}],
  "tasks":    [{"index": 1, "text": "write report", "done": false}],
  "tomorrow": [{"index": 1, "text": "plan sprint"}],
  "macros":   {"protein": 16.0, "carbs": 46.0, "fat": 11.0, "calories": 347},
  "weight":   81.5
}
```

- `weight` is a number, or `null` when none is logged.
- The 1-based `index` in `tasks` / `tomorrow` is exactly what
  `--toggle-task` / `--task-remove` / `--task-tomorrow-remove` expect.
- `macros` totals are summed from the section's CSV rows.

## For agents

- Read state, then act on it by index:

  ```bash
  daily --json | jq -r '.tasks[] | select(.done|not) | .index'   # open tasks
  daily --toggle-task 1                                           # mark #1 done
  ```

- Read a different day with `--offset`:

  ```bash
  daily -N 1 --json      # yesterday's entry as JSON
  ```

- Indices are positional and shift after a `--task-remove`; re-read `--json`
  before the next index-based edit.
- Read and edit modes do not combine: pass `--json` on its own, and run one
  mutation per invocation.
- Diagnostics ("Toggled task #1 ...", "No daily journal entry ...") are on
  stderr; parse only stdout.

## Exit codes

- `0` success.
- `1` the target entry is missing or unreadable. Create it first with
  `today --create` (see the `today` skill).
- `2` usage error (unknown option, or a flag missing its argument).

## Guidelines

- `daily` never creates an entry; use `today --create` first, then `daily`.
- Prefer `--json` over scraping the markdown output; the markdown default is
  for humans and is not a stable machine format.
- Everything targets today's entry unless you pass `--offset` or an explicit
  `<DEN-PATH>`.
