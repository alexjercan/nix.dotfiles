---
name: today
description: Read and edit a day's journal entry in the den with the `today` CLI - locate/create the entry, read the whole day as JSON, and add/remove/toggle tasks, habits, macros, notes and weight non-interactively. Use this skill whenever an agent needs the path to a journal entry, the structured state of a day (habits, tasks, macros, weight, notes) or needs to change it, and whenever the user mentions the daily journal, the den, habits/tasks/macros tracking, or `today`.
---

# today - Read and Edit the Den

Sole journal reader/writer. Entries:
`<den>/Daily/YYYY-MM-DD-Weekday.md`; den resolution: `--den`, `$DEN_PATH`,
`~/personal/the-den`. Never run bare `today`: it opens `$EDITOR`. Agents use
subcommands, usually with `--json`.

## Commands

```bash
today path                         # path only; does not create
today create                       # ensure entry, print path
today show [--json]
today task add "<text>" [--tomorrow]
today task done <index>
today task rm <index> [--tomorrow]
today habit list
today habit toggle "<name>"
today weight [<number>]
today weight --days <N> [--json]
today macros
today macros add "what,protein,carbs,fat"
today note add "<text>" [--tag <word>]
today note list [--tag <word>]
today -N <offset> <subcommand>
today --den <path> <subcommand>
today --help
```

Most reads and mutations support `--json`; mutations return the updated slice.
Diagnostics use stderr. Every subcommand except read-only `path` creates a
missing entry.

`show --json` returns `date`, `file`, `title`, `habits`, 1-based `tasks` and
`tomorrow`, macro totals, and numeric/null `weight`. Use its indices; after
`task rm`, re-read before another indexed edit. One mutation per invocation.

## Behavior

- Tasks are only `- [ ]`/`- [x]`.
- Habit matching ignores emoji. Notes are one day only; `--tag` matches
  `note :: TAG`.
- Weight is numeric; macro cells finite; tags one word.
- Creation is idempotent and carries yesterday's Tomorrow into Today. A first
  entry succeeds with a stderr warning.
- Exit 0 success, 1 runtime error, 2 usage error.

Prefer JSON over human output. Parse only stdout; default target is today.
