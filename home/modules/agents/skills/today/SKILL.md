---
name: today
description: Read and edit the daily journal with the today CLI. Use for journal, tasks, habits, macros, notes, or weight.
disable-model-invocation: true
---

# Today

Read and edit the den with the `today` CLI. Never run bare `today`; it opens `$EDITOR`. Prefer `--json`.

## Commands

```bash
today path
today create
today show --json
today task add "<text>" [--tomorrow]
today task done <index>
today task rm <index> [--tomorrow]
today habit list
today habit toggle "<name>"
today weight [<number>]
today weight --days <N> --json
today macros
today macros add "what,protein,carbs,fat"
today note add "<text>" [--tag <word>]
today note list [--tag <word>]
today -N <offset> <subcommand>
today --help
```

## Rules

* Default target: today. `-N` selects a relative day.
* Prefer JSON for reads and mutations. Parse stdout only.
* Task indices are 1-based.
* After removing a task, re-read before another indexed edit.
* One mutation per invocation.
* `path` does not create an entry; other subcommands may.
* Use `today --help` for details.

