---
name: today
description: Locate or create today's daily journal entry in the den with the `today` CLI, non-interactively. Use this skill whenever an agent needs the path to today's (or the current offset day's) journal file, needs to ensure the entry exists before reading or editing it, or whenever the user mentions the daily journal, the den, or `today`. Pairs with the `daily` skill, which reads and mutates the entry once it exists.
---

# today - Locate or create today's journal entry

`today` opens today's daily journal entry in `$EDITOR` for humans. For agents
it has two non-interactive modes that print the entry's path to stdout and
nothing else, so it composes in scripts. The source is
`home/modules/scripts/today.nix`; entries live under `<den>/Daily/` named
`YYYY-MM-DD-Weekday.md`. It is the companion to the `daily` skill: `today`
ensures the file exists and hands back its path; `daily` reads and edits it.

## Commands

```bash
today                        # Interactive: create if missing, open in $EDITOR
today -c | --create          # Create if missing, print the entry path, exit
today -p | --path            # Print today's entry path WITHOUT creating it
today -t | --template <T>    # Use template <den>/Templates/<T> (default daily.md)
today <DEN-PATH>             # Use a specific den dir instead of the default
today -h | --help            # Usage
```

## For agents

- Never run `today` with no flags: it launches `$EDITOR` and blocks. Use
  `--create` or `--path`.
- `--create` and `--path` write ONLY the absolute entry path to stdout, so
  they compose:

  ```bash
  file=$(today --create)     # ensure today's entry exists, capture its path
  file=$(today --path)       # just resolve the path; do not create anything
  ```

- Creating is idempotent: `--create` returns the existing file's path if it is
  already there, and never overwrites it.
- On a first-ever entry (no previous day to carry `Tomorrow` tasks from),
  `--create` still succeeds and prints a warning to stderr.
- All diagnostics go to stderr; stdout stays clean for capture.

## Exit codes

- `0` success.
- `1` runtime error, e.g. the template `<den>/Templates/<T>` is missing.
- `2` usage error, e.g. an unknown option.

## Typical workflow

```bash
# Ensure today's entry exists, then hand it to the daily tools / an editor pass.
file=$(today --create) || { echo "could not create entry" >&2; exit 1; }
daily --json                      # read the day (see the `daily` skill)
```

## Guidelines

- `today` only creates/opens the entry; to read or change its contents (tasks,
  habits, macros, weight) use `daily`.
- Pass an explicit `<DEN-PATH>` when not operating on the default den; the flag
  order does not matter.
- Do not parse anything but the single path line from stdout in `--create` /
  `--path` modes.
