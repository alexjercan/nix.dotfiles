---
name: tatr
description: Create, list, query, and edit this project's Markdown tasks with Tatr.
---

# Tatr

Tasks live at `tasks/<YYYYMMDD-HHMMSS>/TASK.md`.

```bash
tatr new "Title" -p 100 -t tag
tatr ls --sort priority
tatr ls --filter ':status eq OPEN'
tatr edit <id> --status CLOSED
```

Valid statuses are `OPEN` and `CLOSED`. Use `-r ROOT` for
another project. Edit an existing task body directly.
